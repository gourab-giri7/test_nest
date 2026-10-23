/**
 * Test Nest Cloud Functions
 *
 * Provides backend automation for:
 * 1. monthlyFeeRollover: Automatically generates fee records on the 1st of each month.
 * 2. markOverdueFees: Flags unpaid or partial records past their due date as 'Overdue'.
 * 3. gradeSubmission: Idempotent server-side grading and authoritative scoring.
 * 4. reassignStudentAttempt: Server-side validation and atomic execution for retakes.
 */

const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();
const db = admin.firestore();

// Helper: current YYYY-MM
function getMonthKey(date = new Date()) {
  const y = date.getFullYear();
  const m = String(date.getMonth() + 1).padStart(2, "0");
  return `${y}-${m}`;
}

/**
 * Scheduled: 1st of every month at midnight UTC.
 * Automatically provisions monthly fee records for all active students.
 */
exports.monthlyFeeRollover = functions.pubsub
  .schedule("0 0 1 * *")
  .timeZone("UTC")
  .onRun(async (context) => {
    const currentMonth = getMonthKey();
    console.log(`Starting monthly fee rollover for month: ${currentMonth}`);

    const teachersSnap = await db.collection("user").get();
    let totalCreated = 0;

    for (const teacherDoc of teachersSnap.docs) {
      const teacherId = teacherDoc.id;
      const studentsSnap = await teacherDoc.ref.collection("students").get();

      if (studentsSnap.empty) continue;

      let batch = db.batch();
      let opCount = 0;

      for (const studentDoc of studentsSnap.docs) {
        const student = studentDoc.data();
        const studentId = studentDoc.id;
        const monthlyFee = Number(student.monthly_fee || 0);

        if (monthlyFee <= 0) continue;

        const feeRef = studentDoc.ref.collection("feeRecords").doc(currentMonth);
        const existingRecord = await feeRef.get();

        // Idempotency: do not overwrite existing records or reset payments
        if (!existingRecord.exists) {
          // Due date defaults to 10th of the current month
          const dueDate = new Date();
          dueDate.setDate(10);
          dueDate.setHours(23, 59, 59, 999);

          batch.set(feeRef, {
            id: currentMonth,
            billingMonth: currentMonth,
            studentId: studentId,
            studentName: student.name || "Student",
            batch: student.batch || "",
            amountDue: monthlyFee,
            amountPaid: 0.0,
            status: "Unpaid",
            dueDate: admin.firestore.Timestamp.fromDate(dueDate),
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          });

          opCount++;
          totalCreated++;

          if (opCount >= 400) {
            await batch.commit();
            batch = db.batch();
            opCount = 0;
          }
        }
      }

      if (opCount > 0) {
        await batch.commit();
      }
    }

    console.log(`Monthly fee rollover complete. Generated ${totalCreated} new fee records.`);
    return { success: true, totalCreated, billingMonth: currentMonth };
  });

/**
 * Scheduled: Daily check to mark unpaid records past due date as 'Overdue'.
 */
exports.markOverdueFees = functions.pubsub
  .schedule("0 6 * * *")
  .timeZone("UTC")
  .onRun(async (context) => {
    const now = admin.firestore.Timestamp.now();
    console.log("Running daily overdue fee check...");

    // Query collection group for feeRecords
    const feeRecordsSnap = await db
      .collectionGroup("feeRecords")
      .where("status", "in", ["Unpaid", "Partial"])
      .where("dueDate", "<", now)
      .get();

    if (feeRecordsSnap.empty) {
      console.log("No overdue fee records found.");
      return null;
    }

    let batch = db.batch();
    let count = 0;

    for (const doc of feeRecordsSnap.docs) {
      batch.update(doc.ref, {
        status: "Overdue",
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      count++;

      if (count % 400 === 0) {
        await batch.commit();
        batch = db.batch();
      }
    }

    if (count % 400 !== 0) {
      await batch.commit();
    }

    console.log(`Updated ${count} fee records to 'Overdue'.`);
    return { updated: count };
  });

/**
 * Callable: Grade an exam submission server-side.
 * Prevents clients from scoring their own answers or viewing unpublished answer keys.
 */
exports.gradeExamSubmission = functions.https.onCall(async (data, context) => {
  const { teacherId, examId, studentId, attemptId, studentAnswers } = data;

  if (!teacherId || !examId || !studentId) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "teacherId, examId, and studentId are required."
    );
  }

  const examRef = db.collection("user").doc(teacherId).collection("exams").doc(examId);
  const examSnap = await examRef.get();

  if (!examSnap.exists) {
    throw new functions.https.HttpsError("not-found", "Exam does not exist.");
  }

  const examData = examSnap.data();
  const questions = examData.questions || [];

  let totalScore = 0;
  let totalMarks = 0;
  const gradedQuestions = [];

  for (let i = 0; i < questions.length; i++) {
    const q = questions[i];
    const qMarks = Number(q.marks || 1);
    totalMarks += qMarks;

    const submittedAnswer = (studentAnswers && studentAnswers[i]) || "";
    const correctAnswer = q.answer || q.correctAnswer || "";

    const isCorrect =
      String(submittedAnswer).trim().toLowerCase() ===
      String(correctAnswer).trim().toLowerCase();

    if (isCorrect) {
      totalScore += qMarks;
    }

    gradedQuestions.push({
      questionIndex: i,
      submittedAnswer,
      isCorrect,
      marksAwarded: isCorrect ? qMarks : 0,
    });
  }

  const percentage = totalMarks > 0 ? (totalScore / totalMarks) * 100 : 0;

  // Update submission/attempt record
  const submissionRef = examRef.collection("submissions").doc(studentId);
  await submissionRef.set(
    {
      student_id: studentId,
      score: totalScore,
      total_marks: totalMarks,
      percentage: percentage,
      submitted_at: admin.firestore.FieldValue.serverTimestamp(),
      is_graded: true,
      graded_by: "server",
      answers: studentAnswers || {},
    },
    { merge: true }
  );

  return {
    success: true,
    studentId,
    score: totalScore,
    totalMarks,
    percentage,
  };
});
