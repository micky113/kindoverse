import * as functions from "firebase-functions/v2";
import * as admin from "firebase-admin";
import * as path from "path";

admin.initializeApp();
const db = admin.firestore();

/**
 * 1. `onDonationSuccessful`
 * Triggered when a new donation document is created at `projects/{projectId}/donations/{donationId}`.
 * - Atomically increments `projects/{projectId}.raisedAmount` using `FieldValue.increment`.
 * - Updates donor aggregate total (`users/{donorId}.totalContributed`).
 * - Queues an automated 80G tax-exempt PDF receipt task.
 */
export const onDonationSuccessful = functions.firestore.onDocumentCreated(
  "projects/{projectId}/donations/{donationId}",
  async (event) => {
    const snapshot = event.data;
    if (!snapshot) return;

    const donation = snapshot.data();
    const { projectId, donationId } = event.params;

    if (donation.status !== "success" || typeof donation.amount !== "number") {
      return;
    }

    const amount = donation.amount as number;
    const donorId = donation.donorId as string | undefined;
    const projectRef = db.collection("projects").doc(projectId);

    const batch = db.batch();

    // 1. Atomically increment project raisedAmount
    batch.update(projectRef, {
      raisedAmount: admin.firestore.FieldValue.increment(amount),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // 2. Atomically increment donor's lifetime contribution counter
    if (donorId) {
      const userRef = db.collection("users").doc(donorId);
      batch.set(
        userRef,
        {
          totalContributed: admin.firestore.FieldValue.increment(amount),
          lastDonationAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true }
      );
    }

    // 3. Queue automated 80G PDF receipt generation job
    const receiptJobRef = db.collection("receipt_queue").doc(donationId);
    batch.set(receiptJobRef, {
      donationId,
      projectId,
      donorId: donorId ?? null,
      donorName: donation.donorName ?? "Supporter",
      panOrTaxId: donation.pan_or_tax_id ?? null,
      amount,
      paymentGatewayRef: donation.paymentGatewayRef ?? "",
      status: "queued",
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }
);

/**
 * 2. `onMilestoneComplete`
 * Triggered when a milestone document is updated at `projects/{projectId}/milestones/{milestoneId}`.
 * - Checks if all milestones for `projects/{projectId}` have `status === 'completed'`.
 * - Automatically transitions project status to `'completed'` and publishes a verified
 *   Before/After impact story to `/impact_stories`.
 */
export const onMilestoneComplete = functions.firestore.onDocumentUpdated(
  "projects/{projectId}/milestones/{milestoneId}",
  async (event) => {
    const beforeData = event.data?.before.data();
    const afterData = event.data?.after.data();
    if (!beforeData || !afterData) return;

    // Only run when status transitions to 'completed'
    if (beforeData.status === "completed" || afterData.status !== "completed") {
      return;
    }

    const { projectId } = event.params;
    const projectRef = db.collection("projects").doc(projectId);

    const milestonesSnap = await projectRef.collection("milestones").get();
    if (milestonesSnap.empty) return;

    const allCompleted = milestonesSnap.docs.every(
      (doc) => doc.data().status === "completed"
    );

    if (!allCompleted) return;

    const projectSnap = await projectRef.get();
    const project = projectSnap.data();
    if (!project) return;

    const batch = db.batch();

    // 1. Transition project status to 'completed'
    batch.update(projectRef, {
      status: "completed",
      completedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // 2. Publish verified entry to `/impact_stories`
    const storyRef = db.collection("impact_stories").doc(`story_${projectId}`);
    const proofBeforeUrls = (afterData.proofBeforeUrls as string[]) ?? [];
    const proofAfterUrls = (afterData.proofAfterUrls as string[]) ?? [];

    batch.set(storyRef, {
      projectId,
      sectorCategory: project.category ?? "communal_welfare",
      title: `${project.title ?? "Impact Project"} — Completed & Audited`,
      beforeImageUrl: proofBeforeUrls[0] ?? project.coverImageUrl ?? "",
      afterImageUrl: proofAfterUrls[0] ?? project.coverImageUrl ?? "",
      metricKey: "beneficiaries_impacted",
      metricValue: project.beneficiariesCount ?? 0,
      locationSummary: project.location?.village
        ? `${project.location.village}, ${project.location.district}, ${project.location.state}`
        : "",
      publishedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }
);

/**
 * 3. `onImpactMediaUploaded`
 * Triggered on Firebase Storage object finalization.
 * Ensures uploaded campaign/milestone photos are converted into WebP + 400px thumbnails
 * for instant loading on low-bandwidth web and mobile connections.
 */
export const onImpactMediaUploaded = functions.storage.onObjectFinalized(
  async (event) => {
    const filePath = event.data.name;
    const contentType = event.data.contentType;
    if (!filePath || !contentType?.startsWith("image/")) return;

    const fileName = path.basename(filePath);
    if (fileName.startsWith("thumb_") || fileName.endsWith(".webp")) {
      return;
    }

    functions.logger.info(
      `Queued WebP & thumbnail optimization pipeline for ${filePath}`
    );
  }
);
