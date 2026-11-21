const http = require('http');

const PROJECT_ID = 'testnest-5366f';
const BASE_PATH = `/v1/projects/${PROJECT_ID}/databases/(default)/documents`;

function makeJwt(uid, email = null, emailVerified = false) {
  if (!uid) return null;
  const header = Buffer.from(JSON.stringify({ alg: 'none', typ: 'JWT' })).toString('base64url');
  const payload = Buffer.from(JSON.stringify({
    sub: uid,
    user_id: uid,
    email: email ? email.toLowerCase() : null,
    email_verified: emailVerified,
    firebase: { sign_in_provider: 'password' }
  })).toString('base64url');
  return `${header}.${payload}.`;
}

function toFirestoreValue(val) {
  if (val === null || val === undefined) return { nullValue: null };
  if (typeof val === 'boolean') return { booleanValue: val };
  if (typeof val === 'number') {
    if (Number.isInteger(val)) return { integerValue: String(val) };
    return { doubleValue: val };
  }
  if (typeof val === 'string') return { stringValue: val };
  if (val instanceof Date) return { timestampValue: val.toISOString() };
  if (Array.isArray(val)) {
    return { arrayValue: { values: val.map(toFirestoreValue) } };
  }
  if (typeof val === 'object') {
    const fields = {};
    for (const [k, v] of Object.entries(val)) {
      fields[k] = toFirestoreValue(v);
    }
    return { mapValue: { fields } };
  }
  return { stringValue: String(val) };
}

function toFirestoreFields(obj) {
  const fields = {};
  for (const [k, v] of Object.entries(obj)) {
    fields[k] = toFirestoreValue(v);
  }
  return { fields };
}

function request({ method, path, token, body }) {
  return new Promise((resolve, reject) => {
    const data = body ? JSON.stringify(body) : null;
    const req = http.request({
      hostname: '127.0.0.1',
      port: 8088,
      path: path,
      method: method,
      headers: {
        'Content-Type': 'application/json',
        ...(token ? { 'Authorization': `Bearer ${token}` } : {}),
        ...(data ? { 'Content-Length': Buffer.byteLength(data) } : {})
      }
    }, (res) => {
      let raw = '';
      res.on('data', chunk => raw += chunk);
      res.on('end', () => {
        let json = null;
        try { json = JSON.parse(raw); } catch (e) { json = raw; }
        resolve({ status: res.statusCode, body: json });
      });
    });
    req.on('error', reject);
    if (data) req.write(data);
    req.end();
  });
}

async function getDoc(token, path) {
  return request({ method: 'GET', path: `${BASE_PATH}/${path}`, token });
}

async function setDoc(token, path, data) {
  return request({
    method: 'PATCH',
    path: `${BASE_PATH}/${path}`,
    token,
    body: toFirestoreFields(data)
  });
}

async function updateDoc(token, path, data, maskFields = []) {
  const query = maskFields.length > 0
    ? '?' + maskFields.map(f => `updateMask.fieldPaths=${encodeURIComponent(f)}`).join('&')
    : '';
  return request({
    method: 'PATCH',
    path: `${BASE_PATH}/${path}${query}`,
    token,
    body: toFirestoreFields(data)
  });
}

async function deleteDoc(token, path) {
  return request({ method: 'DELETE', path: `${BASE_PATH}/${path}`, token });
}

async function commitWrites(token, writes) {
  return request({
    method: 'POST',
    path: `${BASE_PATH}:commit`,
    token,
    body: { writes }
  });
}

async function runQuery(token, structuredQuery) {
  return request({
    method: 'POST',
    path: `${BASE_PATH}:runQuery`,
    token,
    body: { structuredQuery }
  });
}

// ── Test Runner ─────────────────────────────────────────────────────────────

const results = [];

function assert(condition, message) {
  if (!condition) {
    throw new Error(`Assertion failed: ${message}`);
  }
}

async function test(name, fn) {
  try {
    await fn();
    results.push({ name, pass: true });
    console.log(`[PASS] ${name}`);
  } catch (e) {
    results.push({ name, pass: false, error: e.message });
    console.error(`[FAIL] ${name}: ${e.message}`);
  }
}

// ── Main Test Suite ─────────────────────────────────────────────────────────

async function main() {
  console.log('================================================================');
  console.log('STARTING ACTUAL FIRESTORE RULES EMULATOR SUITE TEST RUN');
  console.log('Target: Cloud Firestore Emulator on port 8088');
  console.log('Project ID: testnest-5366f');
  console.log('================================================================\n');

  // Test setup tokens
  const adminUid = 'admin_user_001';
  const adminEmail = 'admin@apexacademy.com';
  const adminToken = makeJwt(adminUid, adminEmail, true);

  const teacherUid = 'teacher_jane_002';
  const teacherEmail = 'jane.doe@apexacademy.com';
  const teacherVerifiedToken = makeJwt(teacherUid, teacherEmail, true);
  const teacherUnverifiedToken = makeJwt(teacherUid, teacherEmail, false);

  const wrongEmailUid = 'intruder_bob_003';
  const wrongEmail = 'bob.attacker@other.com';
  const wrongEmailToken = makeJwt(wrongEmailUid, wrongEmail, true);

  const studentUid = 'student_tim_004';
  const studentEmail = 'tim@students.edu';
  const studentToken = makeJwt(studentUid, studentEmail, true);

  const otherAdminUid = 'other_admin_999';
  const otherAdminEmail = 'admin@rivalinstitute.com';
  const otherAdminToken = makeJwt(otherAdminUid, otherAdminEmail, true);

  const orgId = 'org_apex_100';
  const rivalOrgId = 'org_rival_200';

  // ── Setup Organizations ───────────────────────────────────────────────────

  // Admin creates own org org_apex_100
  const createOrgRes = await setDoc(adminToken, `organizations/${orgId}`, {
    name: 'Apex Academy',
    type: 'institute',
    ownerId: adminUid,
    createdAt: new Date(),
    status: 'active'
  });
  assert(createOrgRes.status === 200, `Failed to setup test org: ${JSON.stringify(createOrgRes.body)}`);

  // Admin creates own member record
  const createAdminMemberRes = await setDoc(adminToken, `organizations/${orgId}/members/${adminUid}`, {
    uid: adminUid,
    email: adminEmail,
    name: 'Admin User',
    role: 'admin',
    status: 'active',
    joinedAt: new Date()
  });
  assert(createAdminMemberRes.status === 200, 'Failed to setup admin member doc');

  // Other admin creates rival org
  await setDoc(otherAdminToken, `organizations/${rivalOrgId}`, {
    name: 'Rival Institute',
    type: 'institute',
    ownerId: otherAdminUid,
    createdAt: new Date(),
    status: 'active'
  });
  await setDoc(otherAdminToken, `organizations/${rivalOrgId}/members/${otherAdminUid}`, {
    uid: otherAdminUid,
    email: otherAdminEmail,
    name: 'Other Admin',
    role: 'admin',
    status: 'active',
    joinedAt: new Date()
  });

  // ── Section 2: Required Security Test Cases ───────────────────────────────

  await test('1. Unauthenticated user cannot read or write protected organization data', async () => {
    const readRes = await getDoc(null, `organizations/${orgId}/members/${adminUid}`);
    assert(readRes.status === 403, `Expected 403 but got ${readRes.status}`);

    const writeRes = await setDoc(null, `organizations/${orgId}/batches/batch_hack`, {
      batchName: 'Hacked Batch'
    });
    assert(writeRes.status === 403, `Expected 403 but got ${writeRes.status}`);
  });

  await test('2. Normal Teacher cannot create an invitation for an organization', async () => {
    // Normal teacher trying to create an invitation
    const res = await setDoc(teacherVerifiedToken, 'invitations/TN-INV-TEACHERFAIL', {
      code: 'TN-INV-TEACHERFAIL',
      orgId: orgId,
      orgName: 'Apex Academy',
      teacherEmail: 'friend@test.com',
      createdBy: teacherUid,
      createdAt: new Date(),
      expiresAt: new Date(Date.now() + 7 * 86400000),
      isUsed: false,
      status: 'pending'
    });
    assert(res.status === 403, `Teacher should not create invitation, got ${res.status}`);
  });

  await test('3. Admin can create an invitation for their own organization', async () => {
    const res = await setDoc(adminToken, 'invitations/TN-INV-SUCCESS01', {
      code: 'TN-INV-SUCCESS01',
      orgId: orgId,
      orgName: 'Apex Academy',
      teacherEmail: teacherEmail,
      createdBy: adminUid,
      createdAt: new Date(),
      expiresAt: new Date(Date.now() + 7 * 86400000),
      isUsed: false,
      status: 'pending'
    });
    assert(res.status === 200, `Admin should be allowed to create invitation, got ${res.status}`);

    const orgInviteRes = await setDoc(adminToken, `organizations/${orgId}/invitations/TN-INV-SUCCESS01`, {
      code: 'TN-INV-SUCCESS01',
      orgId: orgId,
      orgName: 'Apex Academy',
      teacherEmail: teacherEmail,
      createdBy: adminUid,
      createdAt: new Date(),
      expiresAt: new Date(Date.now() + 7 * 86400000),
      isUsed: false,
      status: 'pending'
    });
    assert(orgInviteRes.status === 200, `Admin should be allowed to write org invitation doc, got ${orgInviteRes.status}`);
  });

  await test('4. Admin cannot create an invitation for an organization they do not administer', async () => {
    // Admin trying to create invitation for rivalOrgId
    const res = await setDoc(adminToken, 'invitations/TN-INV-UNAUTH01', {
      code: 'TN-INV-UNAUTH01',
      orgId: rivalOrgId,
      orgName: 'Rival Institute',
      teacherEmail: 'spy@rival.com',
      createdBy: adminUid,
      createdAt: new Date(),
      expiresAt: new Date(Date.now() + 7 * 86400000),
      isUsed: false,
      status: 'pending'
    });
    assert(res.status === 403, `Admin cannot forge invitation for another org, got ${res.status}`);
  });

  await test('5. Uninvited user cannot create their own organization membership', async () => {
    const res = await setDoc(wrongEmailToken, `organizations/${orgId}/members/${wrongEmailUid}`, {
      uid: wrongEmailUid,
      email: wrongEmail,
      name: 'Intruder',
      role: 'teacher',
      status: 'active',
      joinedAt: new Date()
    });
    assert(res.status === 403, `Uninvited user must not create membership doc, got ${res.status}`);
  });

  await test('6. Teacher with the wrong email cannot redeem an invitation', async () => {
    // Setup invitation targeted to teacherEmail
    await setDoc(adminToken, 'invitations/TN-INV-TARGET01', {
      code: 'TN-INV-TARGET01',
      orgId: orgId,
      orgName: 'Apex Academy',
      teacherEmail: teacherEmail,
      createdBy: adminUid,
      createdAt: new Date(),
      expiresAt: new Date(Date.now() + 7 * 86400000),
      isUsed: false,
      status: 'pending'
    });
    await setDoc(adminToken, `organizations/${orgId}/invitations/TN-INV-TARGET01`, {
      code: 'TN-INV-TARGET01',
      orgId: orgId,
      orgName: 'Apex Academy',
      teacherEmail: teacherEmail,
      createdBy: adminUid,
      createdAt: new Date(),
      expiresAt: new Date(Date.now() + 7 * 86400000),
      isUsed: false,
      status: 'pending'
    });

    // wrongEmailToken attempts redemption
    const writeRes = await commitWrites(wrongEmailToken, [
      {
        update: {
          name: `projects/${PROJECT_ID}/databases/(default)/documents/invitations/TN-INV-TARGET01`,
          fields: toFirestoreFields({
            isUsed: true,
            status: 'accepted',
            usedBy: wrongEmailUid,
            usedAt: new Date()
          }).fields
        },
        updateMask: { fieldPaths: ['isUsed', 'status', 'usedBy', 'usedAt'] }
      },
      {
        update: {
          name: `projects/${PROJECT_ID}/databases/(default)/documents/organizations/${orgId}/invitations/TN-INV-TARGET01`,
          fields: toFirestoreFields({
            isUsed: true,
            status: 'accepted',
            usedBy: wrongEmailUid,
            usedAt: new Date()
          }).fields
        },
        updateMask: { fieldPaths: ['isUsed', 'status', 'usedBy', 'usedAt'] }
      },
      {
        update: {
          name: `projects/${PROJECT_ID}/databases/(default)/documents/organizations/${orgId}/members/${wrongEmailUid}`,
          fields: toFirestoreFields({
            uid: wrongEmailUid,
            email: wrongEmail,
            name: 'Wrong Email User',
            role: 'teacher',
            status: 'active',
            joinedAt: new Date(),
            inviteCode: 'TN-INV-TARGET01'
          }).fields
        }
      }
    ]);
    assert(writeRes.status === 403, `Wrong email redemption should be 403, got ${writeRes.status}`);
  });

  await test('7. Unverified email cannot redeem an invitation', async () => {
    const writeRes = await commitWrites(teacherUnverifiedToken, [
      {
        update: {
          name: `projects/${PROJECT_ID}/databases/(default)/documents/invitations/TN-INV-TARGET01`,
          fields: toFirestoreFields({
            isUsed: true,
            status: 'accepted',
            usedBy: teacherUid,
            usedAt: new Date()
          }).fields
        },
        updateMask: { fieldPaths: ['isUsed', 'status', 'usedBy', 'usedAt'] }
      },
      {
        update: {
          name: `projects/${PROJECT_ID}/databases/(default)/documents/organizations/${orgId}/invitations/TN-INV-TARGET01`,
          fields: toFirestoreFields({
            isUsed: true,
            status: 'accepted',
            usedBy: teacherUid,
            usedAt: new Date()
          }).fields
        },
        updateMask: { fieldPaths: ['isUsed', 'status', 'usedBy', 'usedAt'] }
      },
      {
        update: {
          name: `projects/${PROJECT_ID}/databases/(default)/documents/organizations/${orgId}/members/${teacherUid}`,
          fields: toFirestoreFields({
            uid: teacherUid,
            email: teacherEmail,
            name: 'Jane Doe',
            role: 'teacher',
            status: 'active',
            joinedAt: new Date(),
            inviteCode: 'TN-INV-TARGET01'
          }).fields
        }
      }
    ]);
    assert(writeRes.status === 403, `Unverified email redemption should be 403, got ${writeRes.status}`);
  });

  await test('8. Correct verified email can redeem a valid invitation via atomic transaction', async () => {
    const writeRes = await commitWrites(teacherVerifiedToken, [
      {
        update: {
          name: `projects/${PROJECT_ID}/databases/(default)/documents/invitations/TN-INV-TARGET01`,
          fields: toFirestoreFields({
            isUsed: true,
            status: 'accepted',
            usedBy: teacherUid,
            usedAt: new Date()
          }).fields
        },
        updateMask: { fieldPaths: ['isUsed', 'status', 'usedBy', 'usedAt'] }
      },
      {
        update: {
          name: `projects/${PROJECT_ID}/databases/(default)/documents/organizations/${orgId}/invitations/TN-INV-TARGET01`,
          fields: toFirestoreFields({
            isUsed: true,
            status: 'accepted',
            usedBy: teacherUid,
            usedAt: new Date()
          }).fields
        },
        updateMask: { fieldPaths: ['isUsed', 'status', 'usedBy', 'usedAt'] }
      },
      {
        update: {
          name: `projects/${PROJECT_ID}/databases/(default)/documents/organizations/${orgId}/members/${teacherUid}`,
          fields: toFirestoreFields({
            uid: teacherUid,
            email: teacherEmail,
            name: 'Jane Doe',
            role: 'teacher',
            status: 'active',
            joinedAt: new Date(),
            inviteCode: 'TN-INV-TARGET01'
          }).fields
        }
      },
      {
        update: {
          name: `projects/${PROJECT_ID}/databases/(default)/documents/users/${teacherUid}/memberships/${orgId}`,
          fields: toFirestoreFields({
            organizationId: orgId,
            organizationName: 'Apex Academy',
            organizationType: 'institute',
            role: 'teacher',
            status: 'active',
            joinedAt: new Date()
          }).fields
        }
      }
    ]);
    assert(writeRes.status === 200, `Redemption should succeed with 200, got ${writeRes.status}: ${JSON.stringify(writeRes.body)}`);
  });

  await test('9. Expired invitation cannot be redeemed', async () => {
    // Admin creates expired invitation
    await setDoc(adminToken, 'invitations/TN-INV-EXPIRED01', {
      code: 'TN-INV-EXPIRED01',
      orgId: orgId,
      orgName: 'Apex Academy',
      teacherEmail: 'another.teacher@test.com',
      createdBy: adminUid,
      createdAt: new Date(Date.now() - 10 * 86400000),
      expiresAt: new Date(Date.now() - 1 * 86400000),
      isUsed: false,
      status: 'pending'
    });
    await setDoc(adminToken, `organizations/${orgId}/invitations/TN-INV-EXPIRED01`, {
      code: 'TN-INV-EXPIRED01',
      orgId: orgId,
      orgName: 'Apex Academy',
      teacherEmail: 'another.teacher@test.com',
      createdBy: adminUid,
      createdAt: new Date(Date.now() - 10 * 86400000),
      expiresAt: new Date(Date.now() - 1 * 86400000),
      isUsed: false,
      status: 'pending'
    });

    const anotherToken = makeJwt('teacher_exp', 'another.teacher@test.com', true);
    const writeRes = await commitWrites(anotherToken, [
      {
        update: {
          name: `projects/${PROJECT_ID}/databases/(default)/documents/invitations/TN-INV-EXPIRED01`,
          fields: toFirestoreFields({
            isUsed: true,
            status: 'accepted',
            usedBy: 'teacher_exp',
            usedAt: new Date()
          }).fields
        },
        updateMask: { fieldPaths: ['isUsed', 'status', 'usedBy', 'usedAt'] }
      },
      {
        update: {
          name: `projects/${PROJECT_ID}/databases/(default)/documents/organizations/${orgId}/invitations/TN-INV-EXPIRED01`,
          fields: toFirestoreFields({
            isUsed: true,
            status: 'accepted',
            usedBy: 'teacher_exp',
            usedAt: new Date()
          }).fields
        },
        updateMask: { fieldPaths: ['isUsed', 'status', 'usedBy', 'usedAt'] }
      },
      {
        update: {
          name: `projects/${PROJECT_ID}/databases/(default)/documents/organizations/${orgId}/members/teacher_exp`,
          fields: toFirestoreFields({
            uid: 'teacher_exp',
            email: 'another.teacher@test.com',
            name: 'Expired Teacher',
            role: 'teacher',
            status: 'active',
            joinedAt: new Date(),
            inviteCode: 'TN-INV-EXPIRED01'
          }).fields
        }
      }
    ]);
    assert(writeRes.status === 403, `Expired invite redemption should fail with 403, got ${writeRes.status}`);
  });

  await test('10. Revoked invitation cannot be redeemed', async () => {
    // Admin creates and revokes an invitation
    await setDoc(adminToken, 'invitations/TN-INV-REVOKED01', {
      code: 'TN-INV-REVOKED01',
      orgId: orgId,
      orgName: 'Apex Academy',
      teacherEmail: 'revoked.teacher@test.com',
      createdBy: adminUid,
      createdAt: new Date(),
      expiresAt: new Date(Date.now() + 7 * 86400000),
      isUsed: false,
      status: 'revoked'
    });
    await setDoc(adminToken, `organizations/${orgId}/invitations/TN-INV-REVOKED01`, {
      code: 'TN-INV-REVOKED01',
      orgId: orgId,
      orgName: 'Apex Academy',
      teacherEmail: 'revoked.teacher@test.com',
      createdBy: adminUid,
      createdAt: new Date(),
      expiresAt: new Date(Date.now() + 7 * 86400000),
      isUsed: false,
      status: 'revoked'
    });

    const revToken = makeJwt('teacher_rev', 'revoked.teacher@test.com', true);
    const writeRes = await commitWrites(revToken, [
      {
        update: {
          name: `projects/${PROJECT_ID}/databases/(default)/documents/invitations/TN-INV-REVOKED01`,
          fields: toFirestoreFields({
            isUsed: true,
            status: 'accepted',
            usedBy: 'teacher_rev',
            usedAt: new Date()
          }).fields
        },
        updateMask: { fieldPaths: ['isUsed', 'status', 'usedBy', 'usedAt'] }
      },
      {
        update: {
          name: `projects/${PROJECT_ID}/databases/(default)/documents/organizations/${orgId}/invitations/TN-INV-REVOKED01`,
          fields: toFirestoreFields({
            isUsed: true,
            status: 'accepted',
            usedBy: 'teacher_rev',
            usedAt: new Date()
          }).fields
        },
        updateMask: { fieldPaths: ['isUsed', 'status', 'usedBy', 'usedAt'] }
      },
      {
        update: {
          name: `projects/${PROJECT_ID}/databases/(default)/documents/organizations/${orgId}/members/teacher_rev`,
          fields: toFirestoreFields({
            uid: 'teacher_rev',
            email: 'revoked.teacher@test.com',
            name: 'Revoked Teacher',
            role: 'teacher',
            status: 'active',
            joinedAt: new Date(),
            inviteCode: 'TN-INV-REVOKED01'
          }).fields
        }
      }
    ]);
    assert(writeRes.status === 403, `Revoked invite redemption should fail with 403, got ${writeRes.status}`);
  });

  await test('11. Already-used invitation cannot be redeemed again', async () => {
    // Attempt to redeem TN-INV-TARGET01 which was already redeemed in test 8
    const secondAttemptToken = makeJwt(teacherUid, teacherEmail, true);
    const writeRes = await commitWrites(secondAttemptToken, [
      {
        update: {
          name: `projects/${PROJECT_ID}/databases/(default)/documents/invitations/TN-INV-TARGET01`,
          fields: toFirestoreFields({
            isUsed: true,
            status: 'accepted',
            usedBy: teacherUid,
            usedAt: new Date()
          }).fields
        },
        updateMask: { fieldPaths: ['isUsed', 'status', 'usedBy', 'usedAt'] }
      }
    ]);
    assert(writeRes.status === 403, `Already-used invitation must reject subsequent redemptions, got ${writeRes.status}`);
  });

  await test('12. Teacher cannot promote themselves to Admin', async () => {
    const updateRes = await updateDoc(
      teacherVerifiedToken,
      `organizations/${orgId}/members/${teacherUid}`,
      { role: 'admin' },
      ['role']
    );
    assert(updateRes.status === 403, `Teacher self-promotion to admin must be 403, got ${updateRes.status}`);
  });

  await test('13. Student cannot create or modify institute exams', async () => {
    // Student tries to create exam in organization
    const createRes = await setDoc(studentToken, `organizations/${orgId}/exams/exam_hack`, {
      examName: 'Student Created Exam',
      teacherId: studentUid
    });
    assert(createRes.status === 403, `Student cannot create exams, got ${createRes.status}`);
  });

  await test('14. Student cannot read protected answer keys', async () => {
    // Setup answer key as Admin
    await setDoc(adminToken, `organizations/${orgId}/exams/exam_01`, {
      examName: 'Midterm'
    });
    await setDoc(adminToken, `organizations/${orgId}/exams/exam_01/answerKeys/q1`, {
      correctOption: 'C',
      explanation: 'Secret answer key'
    });

    const readRes = await getDoc(studentToken, `organizations/${orgId}/exams/exam_01/answerKeys/q1`);
    assert(readRes.status === 403, `Student reading answer key must be 403, got ${readRes.status}`);

    // Verify teacher CAN read answer key
    const teacherReadRes = await getDoc(teacherVerifiedToken, `organizations/${orgId}/exams/exam_01/answerKeys/q1`);
    assert(teacherReadRes.status === 200, `Teacher should be able to read answer key, got ${teacherReadRes.status}`);
  });

  await test('15. Teacher cannot edit another Teacher\'s protected records where ownership is required', async () => {
    // Setup legacy doc for adminUid
    await setDoc(adminToken, `user/${adminUid}`, {
      name: 'Admin Personal Doc'
    });

    // teacherJane attempts to update admin's profile
    const editRes = await setDoc(teacherVerifiedToken, `user/${adminUid}`, {
      name: 'Hacked Admin Doc'
    });
    assert(editRes.status === 403, `Cross-teacher edit must be 403, got ${editRes.status}`);
  });

  await test('16. Existing legacy Teacher paths continue to work according to original rules', async () => {
    // Teacher writes own batch in user/{teacherId}/batches
    const batchRes = await setDoc(teacherVerifiedToken, `user/${teacherUid}/batches/batch_leg_1`, {
      batchName: 'Physics Morning',
      batchCode: 'TN-PHY1'
    });
    assert(batchRes.status === 200, `Teacher should create batch under user/{teacherId}, got ${batchRes.status}`);

    // Teacher writes exam under user/{teacherId}/exams
    const examRes = await setDoc(teacherVerifiedToken, `user/${teacherUid}/exams/exam_leg_1`, {
      examName: 'Physics Unit 1',
      status: 'Active'
    });
    assert(examRes.status === 200, `Teacher should create exam under user/{teacherId}, got ${examRes.status}`);
  });

  await test('17. Existing Student enrollment and profile permissions continue to work', async () => {
    // Student reads own account
    const readProfileRes = await getDoc(studentToken, `users/${studentUid}`);
    // If not found, create is allowed for owner
    const createProfileRes = await setDoc(studentToken, `users/${studentUid}`, {
      name: 'Tim Student',
      role: 'student'
    });
    assert(createProfileRes.status === 200, `Student should write own profile, got ${createProfileRes.status}`);

    // Student cannot elevate role to teacher
    const hackRoleRes = await setDoc(studentToken, `users/${studentUid}`, {
      name: 'Tim Student',
      role: 'teacher'
    });
    assert(hackRoleRes.status === 403, `Student role elevation must be 403, got ${hackRoleRes.status}`);
  });

  // ── Section 3: Atomic Transaction & Concurrent Redemption Tests ──────────

  await test('18. Atomic Transaction: Failed membership write does not consume invitation', async () => {
    // Setup new invitation
    await setDoc(adminToken, 'invitations/TN-INV-ATOMIC01', {
      code: 'TN-INV-ATOMIC01',
      orgId: orgId,
      orgName: 'Apex Academy',
      teacherEmail: 'atomic.teacher@test.com',
      createdBy: adminUid,
      createdAt: new Date(),
      expiresAt: new Date(Date.now() + 7 * 86400000),
      isUsed: false,
      status: 'pending'
    });
    await setDoc(adminToken, `organizations/${orgId}/invitations/TN-INV-ATOMIC01`, {
      code: 'TN-INV-ATOMIC01',
      orgId: orgId,
      orgName: 'Apex Academy',
      teacherEmail: 'atomic.teacher@test.com',
      createdBy: adminUid,
      createdAt: new Date(),
      expiresAt: new Date(Date.now() + 7 * 86400000),
      isUsed: false,
      status: 'pending'
    });

    const atomicToken = makeJwt('teacher_atomic', 'atomic.teacher@test.com', true);

    // Transaction that updates invitation but tries an unauthorized membership write (role: admin)
    const failedTxRes = await commitWrites(atomicToken, [
      {
        update: {
          name: `projects/${PROJECT_ID}/databases/(default)/documents/invitations/TN-INV-ATOMIC01`,
          fields: toFirestoreFields({
            isUsed: true,
            status: 'accepted',
            usedBy: 'teacher_atomic',
            usedAt: new Date()
          }).fields
        },
        updateMask: { fieldPaths: ['isUsed', 'status', 'usedBy', 'usedAt'] }
      },
      {
        update: {
          name: `projects/${PROJECT_ID}/databases/(default)/documents/organizations/${orgId}/invitations/TN-INV-ATOMIC01`,
          fields: toFirestoreFields({
            isUsed: true,
            status: 'accepted',
            usedBy: 'teacher_atomic',
            usedAt: new Date()
          }).fields
        },
        updateMask: { fieldPaths: ['isUsed', 'status', 'usedBy', 'usedAt'] }
      },
      {
        update: {
          name: `projects/${PROJECT_ID}/databases/(default)/documents/organizations/${orgId}/members/teacher_atomic`,
          fields: toFirestoreFields({
            uid: 'teacher_atomic',
            email: 'atomic.teacher@test.com',
            name: 'Atomic Teacher',
            role: 'admin', // ILLEGAL ROLE ESCALATION -> causes whole transaction to fail
            status: 'active',
            joinedAt: new Date(),
            inviteCode: 'TN-INV-ATOMIC01'
          }).fields
        }
      }
    ]);
    assert(failedTxRes.status === 403, `Transaction with illegal membership write must fail, got ${failedTxRes.status}`);

    // Verify invitation document was NOT updated / consumed
    const inviteCheck = await getDoc(adminToken, 'invitations/TN-INV-ATOMIC01');
    assert(inviteCheck.status === 200, 'Admin can read invitation');
    const isUsed = inviteCheck.body.fields.isUsed.booleanValue;
    assert(isUsed === false, `Invitation should still be unused, but isUsed was ${isUsed}`);
  });

  await test('19. Concurrent Redemption Simulation: Second transaction rejected', async () => {
    // Setup fresh invitation
    const code = 'TN-INV-CONCURR01';
    const email = 'concurr.teacher@test.com';
    await setDoc(adminToken, `invitations/${code}`, {
      code,
      orgId,
      orgName: 'Apex Academy',
      teacherEmail: email,
      createdBy: adminUid,
      createdAt: new Date(),
      expiresAt: new Date(Date.now() + 7 * 86400000),
      isUsed: false,
      status: 'pending'
    });
    await setDoc(adminToken, `organizations/${orgId}/invitations/${code}`, {
      code,
      orgId,
      orgName: 'Apex Academy',
      teacherEmail: email,
      createdBy: adminUid,
      createdAt: new Date(),
      expiresAt: new Date(Date.now() + 7 * 86400000),
      isUsed: false,
      status: 'pending'
    });

    const t1 = makeJwt('t1_uid', email, true);
    const t2 = makeJwt('t2_uid', email, true);

    const makeTx = (uid, token) => commitWrites(token, [
      {
        update: {
          name: `projects/${PROJECT_ID}/databases/(default)/documents/invitations/${code}`,
          fields: toFirestoreFields({
            isUsed: true,
            status: 'accepted',
            usedBy: uid,
            usedAt: new Date()
          }).fields
        },
        updateMask: { fieldPaths: ['isUsed', 'status', 'usedBy', 'usedAt'] }
      },
      {
        update: {
          name: `projects/${PROJECT_ID}/databases/(default)/documents/organizations/${orgId}/invitations/${code}`,
          fields: toFirestoreFields({
            isUsed: true,
            status: 'accepted',
            usedBy: uid,
            usedAt: new Date()
          }).fields
        },
        updateMask: { fieldPaths: ['isUsed', 'status', 'usedBy', 'usedAt'] }
      },
      {
        update: {
          name: `projects/${PROJECT_ID}/databases/(default)/documents/organizations/${orgId}/members/${uid}`,
          fields: toFirestoreFields({
            uid,
            email,
            name: `Teacher ${uid}`,
            role: 'teacher',
            status: 'active',
            joinedAt: new Date(),
            inviteCode: code
          }).fields
        }
      }
    ]);

    // Fire first redemption
    const res1 = await makeTx('t1_uid', t1);
    assert(res1.status === 200, `First concurrent redemption should succeed, got ${res1.status}`);

    // Fire second redemption
    const res2 = await makeTx('t2_uid', t2);
    assert(res2.status === 403, `Second concurrent redemption must be rejected with 403, got ${res2.status}`);
  });

  await test('20. Membership index and authoritative org membership cannot disagree', async () => {
    // Attacker tries to create a rogue membership index claiming to be admin of org_apex_100
    // but without an authoritative doc in organizations/org_apex_100/members/intruder_bob_003
    const res = await setDoc(wrongEmailToken, `users/${wrongEmailUid}/memberships/${orgId}`, {
      organizationId: orgId,
      organizationName: 'Apex Academy',
      organizationType: 'institute',
      role: 'admin',
      status: 'active',
      joinedAt: new Date()
    });
    assert(res.status === 403, `Unauthorized membership index write must fail with 403, got ${res.status}`);
  });

  // ── Section 4: Firestore Rules Query Tests ────────────────────────────────

  await test('21. Query Rules: Unconstrained invitation list query denied', async () => {
    // Attempting to query all documents in invitations collection without filter
    const unconstrainedRes = await runQuery(wrongEmailToken, {
      from: [{ collectionId: 'invitations' }]
    });
    // In Firestore rules, an unconstrained query that could return documents not satisfying rules is rejected
    assert(unconstrainedRes.status === 403, `Unconstrained invitation collection query must be rejected with 403, got ${unconstrainedRes.status}`);
  });

  await test('22. Query Rules: Constrained invitation query for own created invites allowed for Admin', async () => {
    const adminQueryRes = await runQuery(adminToken, {
      from: [{ collectionId: 'invitations' }],
      where: {
        fieldFilter: {
          field: { fieldPath: 'createdBy' },
          op: 'EQUAL',
          value: { stringValue: adminUid }
        }
      }
    });
    assert(adminQueryRes.status === 200, `Admin constrained query should succeed with 200, got ${adminQueryRes.status}`);
  });

  // ── Section 5: Phase 2 Batch Assignment & Exam Ownership Tests ──────────────

  await test('23. Phase 2: Admin can create and manage institute batches', async () => {
    const res = await setDoc(adminToken, `organizations/${orgId}/batches/batch_p2_01`, {
      id: 'batch_p2_01',
      name: 'Advanced Mechanics',
      teacher_id: adminUid,
      assigned_teacher_ids: [adminUid],
      active_join_code: 'TN-ADV01',
      is_archived: false,
      student_count: 0
    });
    assert(res.status === 200, `Admin batch creation should succeed with 200, got ${res.status}`);
  });

  await test('24. Phase 2: Admin can update teacher assignments for a batch', async () => {
    const res = await updateDoc(adminToken, `organizations/${orgId}/batches/batch_p2_01`, {
      assigned_teacher_ids: [adminUid, teacherUid]
    }, ['assigned_teacher_ids']);
    assert(res.status === 200, `Admin updating assigned_teacher_ids should succeed with 200, got ${res.status}`);
  });

  await test('25. Phase 2: Non-admin teacher cannot update batch teacher assignments', async () => {
    const res = await updateDoc(teacherVerifiedToken, `organizations/${orgId}/batches/batch_p2_01`, {
      assigned_teacher_ids: [teacherUid, 'intruder_teacher']
    }, ['assigned_teacher_ids']);
    assert(res.status === 403, `Non-admin modifying assigned_teacher_ids must be rejected with 403, got ${res.status}`);
  });

  await test('26. Phase 2: Teacher can create and edit their own institute exam', async () => {
    // Teacher creates exam
    const createRes = await setDoc(teacherVerifiedToken, `organizations/${orgId}/exams/exam_own_01`, {
      exam_id: 'exam_own_01',
      exam_name: 'Vectors Quiz',
      teacher_id: teacherUid,
      batch: 'Advanced Mechanics',
      full_marks: '50'
    });
    assert(createRes.status === 200, `Teacher creating own exam should succeed with 200, got ${createRes.status}`);

    // Teacher updates own exam
    const updateRes = await updateDoc(teacherVerifiedToken, `organizations/${orgId}/exams/exam_own_01`, {
      exam_name: 'Vectors Quiz - Final'
    }, ['exam_name']);
    assert(updateRes.status === 200, `Teacher updating own exam should succeed with 200, got ${updateRes.status}`);
  });

  await test('27. Phase 2: Teacher cannot edit another Teacher\'s institute exam', async () => {
    // Wrong teacher tries to update correctTeacher's exam
    const res = await updateDoc(wrongEmailToken, `organizations/${orgId}/exams/exam_own_01`, {
      exam_name: 'Hacked Exam Title'
    }, ['exam_name']);
    assert(res.status === 403, `Cross-teacher exam edit must be rejected with 403, got ${res.status}`);
  });

  await test('28. Phase 2: Student cannot create institute batch or institute exam', async () => {
    const batchRes = await setDoc(studentToken, `organizations/${orgId}/batches/batch_student_hack`, {
      id: 'batch_student_hack',
      name: 'Rogue Student Batch',
      teacher_id: studentUid
    });
    assert(batchRes.status === 403, `Student batch creation must be rejected with 403, got ${batchRes.status}`);

    const examRes = await setDoc(studentToken, `organizations/${orgId}/exams/exam_student_hack`, {
      exam_id: 'exam_student_hack',
      exam_name: 'Student Exam',
      teacher_id: studentUid
    });
    assert(examRes.status === 403, `Student exam creation must be rejected with 403, got ${examRes.status}`);
  });

  // ── Section 6: Phase 3 Attendance Security Rules Tests ───────────────────

  await test('29. Phase 3: Admin can mark and update attendance in organization', async () => {
    const res = await setDoc(adminToken, `organizations/${orgId}/attendance/batch_p2_01_student_01_2026-11-18`, {
      id: 'batch_p2_01_student_01_2026-11-18',
      organizationId: orgId,
      batchId: 'batch_p2_01',
      batchName: 'Advanced Mechanics',
      studentId: studentUid,
      studentName: 'Alice Student',
      teacherId: adminUid,
      dateKey: '2026-11-18',
      status: 'present',
      markedBy: adminUid,
      markedByName: 'Institute Admin'
    });
    assert(res.status === 200, `Admin marking attendance should succeed with 200, got ${res.status}`);
  });

  await test('30. Phase 3: Assigned Teacher can mark attendance in their assigned batch', async () => {
    // teacherUid is assigned to batch_p2_01
    const res = await setDoc(teacherVerifiedToken, `organizations/${orgId}/attendance/batch_p2_01_student_02_2026-11-18`, {
      id: 'batch_p2_01_student_02_2026-11-18',
      organizationId: orgId,
      batchId: 'batch_p2_01',
      batchName: 'Advanced Mechanics',
      studentId: 'student_another_002',
      studentName: 'Bob Student',
      teacherId: teacherUid,
      dateKey: '2026-11-18',
      status: 'late',
      markedBy: teacherUid,
      markedByName: 'Physics Teacher'
    });
    assert(res.status === 200, `Assigned Teacher marking attendance should succeed with 200, got ${res.status}`);
  });

  await test('31. Phase 3: Unassigned Teacher cannot mark attendance in unassigned batch', async () => {
    // wrongEmailUid is a teacher but NOT assigned to batch_p2_01
    const res = await setDoc(wrongEmailToken, `organizations/${orgId}/attendance/batch_p2_01_student_03_2026-11-18`, {
      id: 'batch_p2_01_student_03_2026-11-18',
      organizationId: orgId,
      batchId: 'batch_p2_01',
      batchName: 'Advanced Mechanics',
      studentId: 'student_another_003',
      studentName: 'Charlie Student',
      teacherId: wrongEmailUid,
      dateKey: '2026-11-18',
      status: 'absent',
      markedBy: wrongEmailUid,
      markedByName: 'Rogue Teacher'
    });
    assert(res.status === 403, `Unassigned Teacher marking attendance must be rejected with 403, got ${res.status}`);
  });

  await test('32. Phase 3: Student cannot create or update attendance records', async () => {
    const res = await setDoc(studentToken, `organizations/${orgId}/attendance/batch_p2_01_student_01_2026-11-18`, {
      id: 'batch_p2_01_student_01_2026-11-18',
      organizationId: orgId,
      batchId: 'batch_p2_01',
      batchName: 'Advanced Mechanics',
      studentId: studentUid,
      studentName: 'Alice Student',
      teacherId: adminUid,
      dateKey: '2026-11-18',
      status: 'present',
      markedBy: studentUid,
      markedByName: 'Student Self'
    });
    assert(res.status === 403, `Student write to attendance must be rejected with 403, got ${res.status}`);
  });

  await test('33. Phase 3: Student can read their own attendance record in organization', async () => {
    const res = await getDoc(studentToken, `organizations/${orgId}/attendance/batch_p2_01_student_01_2026-11-18`);
    assert(res.status === 200, `Student reading own attendance record should succeed with 200, got ${res.status}`);
  });

  await test('34. Phase 3: Student cannot read another student\'s attendance record in organization', async () => {
    // studentUid tries to read student_another_002's attendance
    const res = await getDoc(studentToken, `organizations/${orgId}/attendance/batch_p2_01_student_02_2026-11-18`);
    assert(res.status === 403, `Student reading another student's attendance must be rejected with 403, got ${res.status}`);
  });

  await test('35. Phase 3: Single Teacher can mark attendance under user/{teacherId}/attendance', async () => {
    const res = await setDoc(teacherVerifiedToken, `user/${teacherUid}/attendance/batch_legacy_student_01_2026-11-18`, {
      id: 'batch_legacy_student_01_2026-11-18',
      batchId: 'batch_legacy_01',
      batchName: 'Independent Batch',
      studentId: studentUid,
      studentName: 'Alice Student',
      teacherId: teacherUid,
      dateKey: '2026-11-18',
      status: 'present',
      markedBy: teacherUid,
      markedByName: 'Independent Teacher'
    });
    assert(res.status === 200, `Single teacher marking attendance in user path should succeed with 200, got ${res.status}`);
  });

  await test('36. Phase 3: Student can read their own attendance under user/{teacherId}/attendance', async () => {
    const res = await getDoc(studentToken, `user/${teacherUid}/attendance/batch_legacy_student_01_2026-11-18`);
    assert(res.status === 200, `Student reading own attendance in user path should succeed with 200, got ${res.status}`);
  });

  await test('37. Phase 3: Student cannot create or edit attendance under user/{teacherId}/attendance', async () => {
    const res = await setDoc(studentToken, `user/${teacherUid}/attendance/batch_legacy_student_hack_2026-11-18`, {
      id: 'batch_legacy_student_hack_2026-11-18',
      batchId: 'batch_legacy_01',
      batchName: 'Independent Batch',
      studentId: studentUid,
      studentName: 'Alice Student',
      teacherId: teacherUid,
      dateKey: '2026-11-18',
      status: 'present',
      markedBy: studentUid
    });
    assert(res.status === 403, `Student write to user attendance must be rejected with 403, got ${res.status}`);
  });

  // ── Section 7: Phase 4 Notice System Security Rules Tests ────────────────

  await test('38. Phase 4: Admin can create an organization notice', async () => {
    const res = await setDoc(adminToken, `organizations/${orgId}/notices/notice_admin_01`, {
      id: 'notice_admin_01',
      organizationId: orgId,
      title: 'Annual Institute Day',
      body: 'Celebration will be held on December 15th.',
      category: 'general',
      status: 'published',
      audienceType: 'all',
      targetBatchIds: [],
      targetStudentIds: [],
      createdBy: adminUid,
      createdByName: 'Admin User'
    });
    assert(res.status === 200, `Admin notice creation should succeed with 200, got ${res.status}`);
  });

  await test('39. Phase 4: Admin can read notices in their organization', async () => {
    const res = await getDoc(adminToken, `organizations/${orgId}/notices/notice_admin_01`);
    assert(res.status === 200, `Admin reading notice in own org should succeed with 200, got ${res.status}`);
  });

  await test('40. Phase 4: Admin cannot access another organization\'s notices', async () => {
    // Setup rival org notice
    await setDoc(otherAdminToken, `organizations/${rivalOrgId}/notices/notice_rival_01`, {
      id: 'notice_rival_01',
      organizationId: rivalOrgId,
      title: 'Rival Notice',
      body: 'Internal only',
      status: 'published',
      audienceType: 'all',
      createdBy: otherAdminUid
    });

    const res = await getDoc(adminToken, `organizations/${rivalOrgId}/notices/notice_rival_01`);
    assert(res.status === 403, `Admin reading rival org notice must be rejected with 403, got ${res.status}`);
  });

  await test('41. Phase 4: Admin can target valid organization batches', async () => {
    const res = await setDoc(adminToken, `organizations/${orgId}/notices/notice_admin_batches`, {
      id: 'notice_admin_batches',
      organizationId: orgId,
      title: 'Lab Maintenance',
      body: 'Advanced Mechanics lab is closed tomorrow.',
      category: 'class',
      status: 'published',
      audienceType: 'batches',
      targetBatchIds: ['batch_p2_01'],
      targetBatchNames: ['Advanced Mechanics'],
      targetStudentIds: [],
      createdBy: adminUid,
      createdByName: 'Admin User'
    });
    assert(res.status === 200, `Admin batch-targeted notice creation should succeed with 200, got ${res.status}`);
  });

  await test('42. Phase 4: Assigned teacher can create a notice for an assigned batch', async () => {
    // teacherUid is assigned to batch_p2_01
    const res = await setDoc(teacherVerifiedToken, `organizations/${orgId}/notices/notice_teacher_01`, {
      id: 'notice_teacher_01',
      organizationId: orgId,
      title: 'Mechanics Homework Assigned',
      body: 'Complete problems 1 to 5 from chapter 4.',
      category: 'class',
      status: 'published',
      audienceType: 'batches',
      targetBatchIds: ['batch_p2_01'],
      targetBatchNames: ['Advanced Mechanics'],
      targetStudentIds: [],
      createdBy: teacherUid,
      createdByName: 'Jane Doe'
    });
    assert(res.status === 200, `Assigned teacher notice creation should succeed with 200, got ${res.status}`);
  });

  await test('43. Phase 4: Teacher cannot create a notice for an unassigned batch', async () => {
    // wrongEmailUid is NOT assigned to batch_p2_01
    const res = await setDoc(wrongEmailToken, `organizations/${orgId}/notices/notice_rogue_01`, {
      id: 'notice_rogue_01',
      organizationId: orgId,
      title: 'Rogue Homework',
      body: 'Unauthorized assignment',
      category: 'class',
      status: 'published',
      audienceType: 'batches',
      targetBatchIds: ['batch_p2_01'],
      createdBy: wrongEmailUid,
      createdByName: 'Bob Attacker'
    });
    assert(res.status === 403, `Unassigned teacher creating notice for batch must be rejected with 403, got ${res.status}`);
  });

  await test('44. Phase 4: Teacher cannot publish an unauthorized institute-wide notice', async () => {
    const res = await setDoc(teacherVerifiedToken, `organizations/${orgId}/notices/notice_teacher_all`, {
      id: 'notice_teacher_all',
      organizationId: orgId,
      title: 'Institute Wide Holiday Claim',
      body: 'School is closed for everyone.',
      category: 'holiday',
      status: 'published',
      audienceType: 'all',
      targetBatchIds: [],
      createdBy: teacherUid,
      createdByName: 'Jane Doe'
    });
    assert(res.status === 403, `Teacher publishing institute-wide notice must be rejected with 403, got ${res.status}`);
  });

  await test('45. Phase 4: Teacher can edit their own notice', async () => {
    const res = await updateDoc(teacherVerifiedToken, `organizations/${orgId}/notices/notice_teacher_01`, {
      body: 'Updated: Complete problems 1 to 10 from chapter 4.'
    }, ['body']);
    assert(res.status === 200, `Teacher updating own notice should succeed with 200, got ${res.status}`);
  });

  await test('46. Phase 4: Teacher cannot edit another teacher\'s notice', async () => {
    const res = await updateDoc(wrongEmailToken, `organizations/${orgId}/notices/notice_teacher_01`, {
      body: 'Hacked by Bob'
    }, ['body']);
    assert(res.status === 403, `Teacher modifying another teacher notice must be rejected with 403, got ${res.status}`);
  });

  await test('47. Phase 4: Student can read a published organization-wide notice', async () => {
    // Setup student enrollment record in organizations/{orgId}/students/{studentUid}
    await setDoc(adminToken, `organizations/${orgId}/students/${studentUid}`, {
      auth_uid: studentUid,
      id: studentUid,
      batch_id: 'batch_p2_01',
      name: 'Tim Student'
    });

    const res = await getDoc(studentToken, `organizations/${orgId}/notices/notice_admin_01`);
    assert(res.status === 200, `Student reading published org notice should succeed with 200, got ${res.status}`);
  });

  await test('48. Phase 4: Student can read a published notice targeting their enrolled batch', async () => {
    const res = await getDoc(studentToken, `organizations/${orgId}/notices/notice_teacher_01`);
    assert(res.status === 200, `Student reading enrolled batch notice should succeed with 200, got ${res.status}`);
  });

  await test('49. Phase 4: Student can read a published notice targeting their own student ID', async () => {
    await setDoc(adminToken, `organizations/${orgId}/notices/notice_student_tim_direct`, {
      id: 'notice_student_tim_direct',
      organizationId: orgId,
      title: 'Fee Reminder for Tim',
      body: 'Please clear your monthly installment.',
      category: 'fee',
      status: 'published',
      audienceType: 'students',
      targetBatchIds: [],
      targetStudentIds: [studentUid],
      createdBy: adminUid
    });

    const res = await getDoc(studentToken, `organizations/${orgId}/notices/notice_student_tim_direct`);
    assert(res.status === 200, `Student reading direct notice should succeed with 200, got ${res.status}`);
  });

  await test('50. Phase 4: Student cannot read another batch\'s notice', async () => {
    await setDoc(adminToken, `organizations/${orgId}/notices/notice_other_batch`, {
      id: 'notice_other_batch',
      organizationId: orgId,
      title: 'Chemistry Honors Announcement',
      body: 'Only for Chemistry batch.',
      category: 'class',
      status: 'published',
      audienceType: 'batches',
      targetBatchIds: ['batch_chem_honors_99'],
      targetStudentIds: [],
      createdBy: adminUid
    });

    const res = await getDoc(studentToken, `organizations/${orgId}/notices/notice_other_batch`);
    assert(res.status === 403, `Student reading other batch notice must be rejected with 403, got ${res.status}`);
  });

  await test('51. Phase 4: Student cannot read drafts', async () => {
    await setDoc(adminToken, `organizations/${orgId}/notices/notice_draft_secret`, {
      id: 'notice_draft_secret',
      organizationId: orgId,
      title: 'Draft Surprise Test',
      body: 'Surprise test planned tomorrow.',
      category: 'exam',
      status: 'draft',
      audienceType: 'all',
      createdBy: adminUid
    });

    const res = await getDoc(studentToken, `organizations/${orgId}/notices/notice_draft_secret`);
    assert(res.status === 403, `Student reading draft notice must be rejected with 403, got ${res.status}`);
  });

  await test('52. Phase 4: Student cannot read archived notices', async () => {
    await setDoc(adminToken, `organizations/${orgId}/notices/notice_archived_old`, {
      id: 'notice_archived_old',
      organizationId: orgId,
      title: 'Old Notice',
      body: 'Expired historical announcement',
      category: 'general',
      status: 'archived',
      audienceType: 'all',
      createdBy: adminUid
    });

    const res = await getDoc(studentToken, `organizations/${orgId}/notices/notice_archived_old`);
    assert(res.status === 403, `Student reading archived notice must be rejected with 403, got ${res.status}`);
  });

  await test('53. Phase 4: Student cannot create or edit notices', async () => {
    const res = await setDoc(studentToken, `organizations/${orgId}/notices/notice_student_hack`, {
      id: 'notice_student_hack',
      title: 'Student Announcement',
      body: 'Free period today!',
      status: 'published',
      audienceType: 'all',
      createdBy: studentUid
    });
    assert(res.status === 403, `Student creating notice must be rejected with 403, got ${res.status}`);
  });

  await test('54. Phase 4: Single Teacher can manage notices in their own workspace', async () => {
    const res = await setDoc(teacherVerifiedToken, `user/${teacherUid}/notices/notice_legacy_01`, {
      id: 'notice_legacy_01',
      teacherId: teacherUid,
      title: 'Single Teacher Physics Class',
      body: 'Bring calculator tomorrow.',
      category: 'class',
      status: 'published',
      audienceType: 'all',
      createdBy: teacherUid,
      createdByName: 'Jane Doe'
    });
    assert(res.status === 200, `Single teacher notice creation should succeed with 200, got ${res.status}`);
  });

  await test('55. Phase 4: Student can read relevant Single Teacher notice', async () => {
    const res = await getDoc(studentToken, `user/${teacherUid}/notices/notice_legacy_01`);
    assert(res.status === 200, `Student reading published single teacher notice should succeed with 200, got ${res.status}`);
  });

  await test('56. Phase 4: Another teacher cannot access the legacy workspace\'s notices', async () => {
    // wrongEmailToken attempts to write to teacherUid's notices
    const writeRes = await setDoc(wrongEmailToken, `user/${teacherUid}/notices/notice_intruder_01`, {
      id: 'notice_intruder_01',
      title: 'Intruder Notice',
      body: 'Hacked',
      status: 'published',
      audienceType: 'all',
      createdBy: wrongEmailUid
    });
    assert(writeRes.status === 403, `Outsider writing to teacher workspace must be rejected with 403, got ${writeRes.status}`);

    // wrongEmailToken attempts to read teacherUid's draft notice
    await setDoc(teacherVerifiedToken, `user/${teacherUid}/notices/notice_legacy_draft`, {
      id: 'notice_legacy_draft',
      title: 'Teacher Private Notes',
      status: 'draft',
      audienceType: 'all',
      createdBy: teacherUid
    });
    const readRes = await getDoc(wrongEmailToken, `user/${teacherUid}/notices/notice_legacy_draft`);
    assert(readRes.status === 403, `Outsider reading teacher draft notice must be rejected with 403, got ${readRes.status}`);
  });

  await test('57. Phase 4: Unauthorized users cannot delete or alter notices', async () => {
    // Teacher attempts to delete admin notice
    const teacherDelRes = await deleteDoc(teacherVerifiedToken, `organizations/${orgId}/notices/notice_admin_01`);
    assert(teacherDelRes.status === 403, `Non-admin deleting notice must be rejected with 403, got ${teacherDelRes.status}`);

    // Student attempts to delete admin notice
    const studentDelRes = await deleteDoc(studentToken, `organizations/${orgId}/notices/notice_admin_01`);
    assert(studentDelRes.status === 403, `Student deleting notice must be rejected with 403, got ${studentDelRes.status}`);

    // Admin deletes own notice
    const adminDelRes = await deleteDoc(adminToken, `organizations/${orgId}/notices/notice_admin_01`);
    assert(adminDelRes.status === 200, `Admin deleting notice should succeed with 200, got ${adminDelRes.status}`);
  });

  // ── Section 7: Phase 5 Student Performance Intelligence Tests ──────────────

  await test('58. Phase 5: Admin can read organization performance data', async () => {
    // Admin creates exam
    await setDoc(adminToken, `organizations/${orgId}/exams/exam_perf_01`, {
      exam_id: 'exam_perf_01',
      exam_name: 'Mechanics Midterm',
      teacher_id: adminUid,
      batch: 'batch_p2_01',
      full_marks: '100',
      subject: 'Physics'
    });

    // Admin creates student submission
    await setDoc(adminToken, `organizations/${orgId}/exams/exam_perf_01/submissions/${studentUid}`, {
      student_id: studentUid,
      student_name: 'Tim Student',
      exam_id: 'exam_perf_01',
      exam_name: 'Mechanics Midterm',
      batch: 'batch_p2_01',
      score: 85,
      full_marks: '100',
      status: 'submitted',
      correct_count: 8,
      total_questions: 10,
      attempted: 10
    });

    const res = await getDoc(adminToken, `organizations/${orgId}/exams/exam_perf_01/submissions/${studentUid}`);
    assert(res.status === 200, `Admin reading submission should succeed with 200, got ${res.status}`);
  });

  await test('59. Phase 5: Admin cannot access another organization\'s results', async () => {
    // Setup rival exam and submission
    await setDoc(otherAdminToken, `organizations/${rivalOrgId}/exams/exam_rival_perf`, {
      exam_id: 'exam_rival_perf',
      exam_name: 'Rival Quiz',
      teacher_id: otherAdminUid,
      batch: 'rival_batch_01',
      full_marks: '50'
    });
    await setDoc(otherAdminToken, `organizations/${rivalOrgId}/exams/exam_rival_perf/submissions/rival_student`, {
      student_id: 'rival_student',
      score: 45,
      full_marks: '50',
      status: 'submitted'
    });

    const res = await getDoc(adminToken, `organizations/${rivalOrgId}/exams/exam_rival_perf/submissions/rival_student`);
    assert(res.status === 403, `Admin reading rival org submission must be rejected with 403, got ${res.status}`);
  });

  await test('60. Phase 5: Assigned teacher can access assigned-batch results', async () => {
    // teacherUid is assigned to batch_p2_01
    const res = await getDoc(teacherVerifiedToken, `organizations/${orgId}/exams/exam_perf_01/submissions/${studentUid}`);
    assert(res.status === 200, `Assigned teacher reading batch submission should succeed with 200, got ${res.status}`);
  });

  await test('61. Phase 5: Teacher cannot access unassigned-batch results', async () => {
    // Setup batch without teacherUid
    await setDoc(adminToken, `organizations/${orgId}/batches/batch_unassigned`, {
      id: 'batch_unassigned',
      name: 'Unassigned Chemistry',
      teacher_id: adminUid,
      assigned_teacher_ids: [adminUid]
    });
    await setDoc(adminToken, `organizations/${orgId}/exams/exam_unassigned`, {
      exam_id: 'exam_unassigned',
      exam_name: 'Chemistry Test',
      teacher_id: adminUid,
      batch: 'batch_unassigned',
      full_marks: '100'
    });
    await setDoc(adminToken, `organizations/${orgId}/exams/exam_unassigned/submissions/${studentUid}`, {
      student_id: studentUid,
      score: 70,
      full_marks: '100',
      status: 'submitted'
    });

    const res = await getDoc(teacherVerifiedToken, `organizations/${orgId}/exams/exam_unassigned/submissions/${studentUid}`);
    assert(res.status === 403, `Unassigned teacher reading unassigned batch submission must be rejected with 403, got ${res.status}`);
  });

  await test('62. Phase 5: Teacher cannot access unauthorized exam submissions', async () => {
    // wrongEmailToken (outsider) attempts to read exam_perf_01 submission
    const res = await getDoc(wrongEmailToken, `organizations/${orgId}/exams/exam_perf_01/submissions/${studentUid}`);
    assert(res.status === 403, `Outsider reading submission must be rejected with 403, got ${res.status}`);
  });

  await test('63. Phase 5: Student can read their own detailed results', async () => {
    const res = await getDoc(studentToken, `organizations/${orgId}/exams/exam_perf_01/submissions/${studentUid}`);
    assert(res.status === 200, `Student reading own submission should succeed with 200, got ${res.status}`);
  });

  await test('64. Phase 5: Student cannot read another student\'s detailed results', async () => {
    await setDoc(adminToken, `organizations/${orgId}/exams/exam_perf_01/submissions/student_secret_99`, {
      student_id: 'student_secret_99',
      score: 95,
      full_marks: '100',
      status: 'submitted'
    });

    const res = await getDoc(studentToken, `organizations/${orgId}/exams/exam_perf_01/submissions/student_secret_99`);
    assert(res.status === 403, `Student reading another student detailed submission must be rejected with 403, got ${res.status}`);
  });

  await test('65. Phase 5: Student cannot modify exam submissions through analytics', async () => {
    const res = await updateDoc(studentToken, `organizations/${orgId}/exams/exam_perf_01/submissions/${studentUid}`, {
      score: 100,
      correct_count: 10
    }, ['score', 'correct_count']);
    assert(res.status === 403, `Student altering submitted score must be rejected with 403, got ${res.status}`);
  });

  await test('66. Phase 5: Unauthorized users cannot access private leaderboard data', async () => {
    // Admin writes leaderboard summary
    await setDoc(adminToken, `organizations/${orgId}/batches/batch_p2_01/leaderboard/${studentUid}`, {
      studentId: studentUid,
      studentName: 'Tim Student',
      rank: 1,
      avgPercentage: 85.0,
      totalExams: 1
    });

    // Enrolled student can read batch leaderboard summary
    const studentRead = await getDoc(studentToken, `organizations/${orgId}/batches/batch_p2_01/leaderboard/${studentUid}`);
    assert(studentRead.status === 200, `Enrolled student can read batch leaderboard summary, got ${studentRead.status}`);

    // Outsider cannot read or write private leaderboard
    const rivalRead = await getDoc(otherAdminToken, `organizations/${orgId}/batches/batch_p2_01/leaderboard/${studentUid}`);
    assert(rivalRead.status === 403, `Rival admin reading leaderboard must be rejected with 403, got ${rivalRead.status}`);

    const rivalWrite = await setDoc(otherAdminToken, `organizations/${orgId}/batches/batch_p2_01/leaderboard/hacked`, {
      rank: 99
    });
    assert(rivalWrite.status === 403, `Rival admin writing leaderboard must be rejected with 403, got ${rivalWrite.status}`);
  });

  await test('67. Phase 5: Single Teacher can access their own workspace analytics', async () => {
    // Teacher writes exam and submission in legacy workspace
    await setDoc(teacherVerifiedToken, `user/${teacherUid}/exams/exam_leg_01`, {
      exam_id: 'exam_leg_01',
      exam_name: 'Single Teacher Physics'
    });
    await setDoc(teacherVerifiedToken, `user/${teacherUid}/exams/exam_leg_01/submissions/${studentUid}`, {
      student_id: studentUid,
      score: 88,
      full_marks: '100',
      status: 'submitted'
    });

    const res = await getDoc(teacherVerifiedToken, `user/${teacherUid}/exams/exam_leg_01/submissions/${studentUid}`);
    assert(res.status === 200, `Single teacher reading own submission should succeed with 200, got ${res.status}`);
  });

  await test('68. Phase 5: Another teacher cannot access legacy private analytics', async () => {
    const res = await getDoc(wrongEmailToken, `user/${teacherUid}/exams/exam_leg_01/submissions/${studentUid}`);
    assert(res.status === 403, `Other teacher accessing legacy private submission must be rejected with 403, got ${res.status}`);
  });

  await test('69. Phase 5: Student cannot access another teacher\'s legacy results', async () => {
    // Admin creates legacy doc for someone else
    await setDoc(adminToken, `user/${adminUid}/exams/exam_admin_secret`, {
      exam_name: 'Admin Private Exam'
    });
    await setDoc(adminToken, `user/${adminUid}/exams/exam_admin_secret/submissions/secret_student`, {
      student_id: 'secret_student',
      score: 99,
      status: 'submitted'
    });

    const res = await getDoc(studentToken, `user/${adminUid}/exams/exam_admin_secret/submissions/secret_student`);
    assert(res.status === 403, `Student reading another teacher legacy submission must be rejected with 403, got ${res.status}`);
  });

  // ── Step 2 Core Architecture & User Relationship Tests (70–86) ────────────

  await test('70. Step 2: Owner can create and manage their coaching institute', async () => {
    // Owner creates a batch
    const batchRes = await setDoc(adminToken, `organizations/${orgId}/batches/batch_step2_01`, {
      name: 'Class 12 Advanced Physics',
      ownerId: adminUid,
      student_count: 0
    });
    assert(batchRes.status === 200, `Owner should be able to create batch, got ${batchRes.status}`);

    // Owner updates institute metadata
    const orgUpdate = await updateDoc(adminToken, `organizations/${orgId}`, {
      status: 'active',
      name: 'Apex Academy Premier'
    }, ['name']);
    assert(orgUpdate.status === 200, `Owner should update org metadata, got ${orgUpdate.status}`);
  });

  await test('71. Step 2: Teacher cannot edit organization settings', async () => {
    const res = await updateDoc(teacherVerifiedToken, `organizations/${orgId}`, {
      name: 'Hacked Academy'
    }, ['name']);
    assert(res.status === 403, `Teacher must not edit org settings, got ${res.status}`);
  });

  await test('72. Step 2: Teacher can read assigned batches', async () => {
    // Owner creates batch with teacherUid assigned
    await setDoc(adminToken, `organizations/${orgId}/batches/batch_step2_assigned`, {
      name: 'Batch Assigned To Jane',
      assigned_teacher_ids: [teacherUid]
    });

    const res = await getDoc(teacherVerifiedToken, `organizations/${orgId}/batches/batch_step2_assigned`);
    assert(res.status === 200, `Assigned teacher should read assigned batch, got ${res.status}`);
  });

  await test('73. Step 2: Teacher CANNOT read unassigned batch students', async () => {
    // Owner creates batch without teacherUid and enrolls a student
    await setDoc(adminToken, `organizations/${orgId}/batches/batch_step2_unassigned`, {
      name: 'Batch Unassigned To Jane',
      assigned_teacher_ids: [adminUid]
    });
    await setDoc(adminToken, `organizations/${orgId}/batches/batch_step2_unassigned/students/std_secret_01`, {
      studentUid: 'std_secret_01',
      studentName: 'Secret Student',
      status: 'active'
    });

    const res = await getDoc(teacherVerifiedToken, `organizations/${orgId}/batches/batch_step2_unassigned/students/std_secret_01`);
    assert(res.status === 403, `Teacher must not read unassigned batch students, got ${res.status}`);
  });

  await test('74. Step 2: Teacher CANNOT assign themselves to batches', async () => {
    const res = await updateDoc(teacherVerifiedToken, `organizations/${orgId}/batches/batch_step2_unassigned`, {
      assigned_teacher_ids: [adminUid, teacherUid]
    }, ['assigned_teacher_ids']);
    assert(res.status === 403, `Teacher cannot assign themselves to batches, got ${res.status}`);
  });

  await test('75. Step 2: Student can submit join request to organization', async () => {
    const res = await setDoc(studentToken, `organizations/${orgId}/joinRequests/req_std_step2_01`, {
      student_uid: studentUid,
      student_name: 'Tim Student',
      student_email: studentEmail,
      orgId: orgId,
      status: 'pending'
    });
    assert(res.status === 200, `Student should be able to submit join request, got ${res.status}`);
  });

  await test('76. Step 2: Student CANNOT approve their own join request', async () => {
    const res = await updateDoc(studentToken, `organizations/${orgId}/joinRequests/req_std_step2_01`, {
      status: 'approved'
    }, ['status']);
    assert(res.status === 403, `Student must not approve their own join request, got ${res.status}`);
  });

  await test('77. Step 2: Owner can approve student join request', async () => {
    // Owner updates request to approved
    const approveRes = await updateDoc(adminToken, `organizations/${orgId}/joinRequests/req_std_step2_01`, {
      status: 'approved',
      reviewed_by: adminUid
    }, ['status', 'reviewed_by']);
    assert(approveRes.status === 200, `Owner should approve request, got ${approveRes.status}`);

    // Owner creates student member doc
    const memberRes = await setDoc(adminToken, `organizations/${orgId}/members/${studentUid}`, {
      uid: studentUid,
      email: studentEmail,
      name: 'Tim Student',
      role: 'student',
      status: 'active',
      joinedAt: new Date()
    });
    assert(memberRes.status === 200, `Owner should create student member record, got ${memberRes.status}`);
  });

  await test('78. Step 2: Teacher CANNOT approve student join request', async () => {
    const otherStudentUid = 'student_sam_005';
    const otherStudentToken = makeJwt(otherStudentUid, 'sam@students.edu', true);

    await setDoc(otherStudentToken, `organizations/${orgId}/joinRequests/req_std_step2_02`, {
      student_uid: otherStudentUid,
      student_name: 'Sam Student',
      orgId: orgId,
      status: 'pending'
    });

    const res = await updateDoc(teacherVerifiedToken, `organizations/${orgId}/joinRequests/req_std_step2_02`, {
      status: 'approved',
      reviewed_by: teacherUid
    }, ['status', 'reviewed_by']);
    assert(res.status === 403, `Teacher must not approve student join request, got ${res.status}`);
  });

  await test('79. Step 2: Owner can enroll student into batch', async () => {
    const res = await setDoc(adminToken, `organizations/${orgId}/batches/batch_step2_01/students/${studentUid}`, {
      studentUid: studentUid,
      student_name: 'Tim Student',
      batchId: 'batch_step2_01',
      status: 'active',
      enrolledAt: new Date()
    });
    assert(res.status === 200, `Owner should enroll student into batch, got ${res.status}`);
  });

  await test('80. Step 2: Teacher CANNOT enroll student into batch', async () => {
    const res = await setDoc(teacherVerifiedToken, `organizations/${orgId}/batches/batch_step2_01/students/std_intruder`, {
      studentUid: 'std_intruder',
      student_name: 'Intruder',
      status: 'active'
    });
    assert(res.status === 403, `Teacher must not enroll student into batch, got ${res.status}`);
  });

  await test('81. Step 2: Enrolled student can read their batch info and enrollment', async () => {
    const res = await getDoc(studentToken, `organizations/${orgId}/batches/batch_step2_01/students/${studentUid}`);
    assert(res.status === 200, `Enrolled student should read their own enrollment, got ${res.status}`);
  });

  await test('82. Step 2: Student CANNOT read other batches they are not enrolled in', async () => {
    const res = await getDoc(studentToken, `organizations/${orgId}/batches/batch_step2_unassigned/students/std_secret_01`);
    assert(res.status === 403, `Student must not read unassigned batch students, got ${res.status}`);
  });

  await test('83. Step 2: Teacher CANNOT delete students from institute', async () => {
    const delMemberRes = await deleteDoc(teacherVerifiedToken, `organizations/${orgId}/members/${studentUid}`);
    assert(delMemberRes.status === 403, `Teacher must not delete student from org members, got ${delMemberRes.status}`);

    const delBatchStudentRes = await deleteDoc(teacherVerifiedToken, `organizations/${orgId}/batches/batch_step2_01/students/${studentUid}`);
    assert(delBatchStudentRes.status === 403, `Teacher must not delete student from batch, got ${delBatchStudentRes.status}`);
  });

  await test('84. Step 2: Teacher CANNOT access institute financial records', async () => {
    // Owner creates institute fee record
    await setDoc(adminToken, `organizations/${orgId}/feeRecords/fee_record_step2_01`, {
      title: 'October 2026 Collection',
      totalAmount: 50000
    });

    const teacherRes = await getDoc(teacherVerifiedToken, `organizations/${orgId}/feeRecords/fee_record_step2_01`);
    assert(teacherRes.status === 403, `Teacher must not access institute financial records, got ${teacherRes.status}`);

    const adminRes = await getDoc(adminToken, `organizations/${orgId}/feeRecords/fee_record_step2_01`);
    assert(adminRes.status === 200, `Owner should access institute financial records, got ${adminRes.status}`);
  });

  await test('85. Step 2: Unenrolled student CANNOT access institute exams', async () => {
    const unenrolledUid = 'student_unenrolled_006';
    const unenrolledToken = makeJwt(unenrolledUid, 'un@student.com', true);

    const res = await getDoc(unenrolledToken, `organizations/${orgId}/exams/exam_perf_01/submissions/${studentUid}`);
    assert(res.status === 403, `Unenrolled student cannot access private submissions, got ${res.status}`);
  });

  await test('86. Step 2: Cross-tenant isolation: User from Institute A cannot access Institute B data', async () => {
    const crossMemberRes = await getDoc(otherAdminToken, `organizations/${orgId}/members/${adminUid}`);
    assert(crossMemberRes.status === 403, `Rival admin cannot read institute A member, got ${crossMemberRes.status}`);

    const crossBatchRes = await getDoc(otherAdminToken, `organizations/${orgId}/batches/batch_step2_01/students/${studentUid}`);
    assert(crossBatchRes.status === 403, `Rival admin cannot read institute A batch student, got ${crossBatchRes.status}`);
  });

  // ── Section 8: Step 4 Teacher Portal & Salary Rules Tests ────────────────
  await test('87. Step 4: Admin can create and manage salary records in organization', async () => {
    const res = await setDoc(adminToken, `organizations/${orgId}/salaries/sal_001`, {
      id: 'sal_001',
      org_id: orgId,
      teacher_uid: teacherUid,
      teacher_name: 'Jane Doe',
      amount: 45000,
      month: 'October 2026',
      status: 'paid'
    });
    assert(res.status === 200, `Admin creating salary record should succeed with 200, got ${res.status}`);
  });

  await test('88. Step 4: Teacher can read their own salary records', async () => {
    const res = await getDoc(teacherVerifiedToken, `organizations/${orgId}/salaries/sal_001`);
    assert(res.status === 200, `Teacher reading their own salary record should succeed with 200, got ${res.status}`);
  });

  await test('89. Step 4: Teacher CANNOT read another teacher\'s salary record', async () => {
    // Setup salary for second teacher
    await setDoc(adminToken, `organizations/${orgId}/salaries/sal_other_002`, {
      id: 'sal_other_002',
      org_id: orgId,
      teacher_uid: 'other_teacher_xyz',
      teacher_name: 'Bob Smith',
      amount: 50000,
      month: 'October 2026',
      status: 'paid'
    });

    const res = await getDoc(teacherVerifiedToken, `organizations/${orgId}/salaries/sal_other_002`);
    assert(res.status === 403, `Teacher reading another teacher's salary record must be rejected with 403, got ${res.status}`);
  });

  await test('90. Step 4: Teacher CANNOT create or write salary records', async () => {
    const res = await setDoc(teacherVerifiedToken, `organizations/${orgId}/salaries/sal_hack`, {
      id: 'sal_hack',
      org_id: orgId,
      teacher_uid: teacherUid,
      teacher_name: 'Jane Doe',
      amount: 999999,
      month: 'October 2026',
      status: 'paid'
    });
    assert(res.status === 403, `Teacher attempting to create salary record must be rejected with 403, got ${res.status}`);
  });

  await test('91. Step 4: Student CANNOT read teacher salary records', async () => {
    const res = await getDoc(studentToken, `organizations/${orgId}/salaries/sal_001`);
    assert(res.status === 403, `Student reading teacher salary record must be rejected with 403, got ${res.status}`);
  });

  await test('92. Step 4: Unauthenticated user CANNOT read teacher salary records', async () => {
    const res = await getDoc(null, `organizations/${orgId}/salaries/sal_001`);
    assert(res.status === 403, `Unauthenticated user reading salary record must be rejected with 403, got ${res.status}`);
  });

  // ── Section 9: Step 5 Student Portal Fee & Enrollment Rules Tests ─────────
  await test('93. Step 5: Admin can create and manage student fee records in organization', async () => {
    const res = await setDoc(adminToken, `organizations/${orgId}/feeRecords/${studentUid}`, {
      id: studentUid,
      student_uid: studentUid,
      org_id: orgId,
      student_name: 'Alice Walker',
      monthly_fee: 1500.0,
      total_due: 3000.0,
      total_paid: 1500.0,
      status: 'partial'
    });
    assert(res.status === 200, `Admin creating fee record should succeed with 200, got ${res.status}`);
  });

  await test('94. Step 5: Student can read their own fee record in organization', async () => {
    const res = await getDoc(studentToken, `organizations/${orgId}/feeRecords/${studentUid}`);
    assert(res.status === 200, `Student reading own fee record should succeed with 200, got ${res.status}`);
  });

  await test('95. Step 5: Student CANNOT read another student\'s fee record in organization', async () => {
    // Admin creates fee record for student 2
    await setDoc(adminToken, `organizations/${orgId}/feeRecords/other_student_999`, {
      id: 'other_student_999',
      student_uid: 'other_student_999',
      org_id: orgId,
      student_name: 'Bob Other',
      monthly_fee: 2000.0,
      total_due: 2000.0,
      total_paid: 0.0,
      status: 'due'
    });

    const res = await getDoc(studentToken, `organizations/${orgId}/feeRecords/other_student_999`);
    assert(res.status === 403, `Student reading another student fee record must be rejected with 403, got ${res.status}`);
  });

  await test('96. Step 5: Student CANNOT write or delete fee records', async () => {
    const res = await setDoc(studentToken, `organizations/${orgId}/feeRecords/hack_fee`, {
      id: 'hack_fee',
      student_uid: studentUid,
      total_due: 0
    });
    assert(res.status === 403, `Student write fee record must be rejected with 403, got ${res.status}`);
  });

  await test('97. Step 5: Student can read their own batch enrollment in organization', async () => {
    const res = await getDoc(studentToken, `organizations/${orgId}/batches/batch_step2_01/students/${studentUid}`);
    assert(res.status === 200, `Student reading own batch enrollment doc should succeed with 200, got ${res.status}`);
  });

  await test('98. Step 5: Student CANNOT enroll themselves into a batch', async () => {
    const res = await setDoc(studentToken, `organizations/${orgId}/batches/batch_step2_01/students/student_self_enroll`, {
      student_uid: studentUid,
      status: 'active'
    });
    assert(res.status === 403, `Student self-enrollment must be rejected with 403, got ${res.status}`);
  });

  await test('99. Step 5: Student CANNOT delete other students\' enrollments', async () => {
    const res = await deleteDoc(studentToken, `organizations/${orgId}/batches/batch_step2_01/students/student_02`);
    assert(res.status === 403, `Student deleting another enrollment must be rejected with 403, got ${res.status}`);
  });

  // ── Section 10: Step 6 Financial Management Rules Tests ──────────────────
  await test('100. Step 6: Admin can create monthly fee record under student months subcollection', async () => {
    const res = await setDoc(adminToken, `organizations/${orgId}/feeRecords/${studentUid}/months/2026-11`, {
      billing_month: '2026-11',
      student_id: studentUid,
      student_name: 'Alice Walker',
      org_id: orgId,
      amount_due: 3500.0,
      amount_paid: 0.0,
      balance: 3500.0,
      status: 'pending'
    });
    assert(res.status === 200, `Admin creating monthly fee record should succeed with 200, got ${res.status}`);
  });

  await test('101. Step 6: Admin can record student payment in append-only payments subcollection', async () => {
    const res = await setDoc(adminToken, `organizations/${orgId}/feeRecords/${studentUid}/months/2026-11/payments/pay_nov_01`, {
      payment_id: 'pay_nov_01',
      amount: 1500.0,
      method: 'upi',
      student_uid: studentUid,
      recorded_by: 'Institute Owner'
    });
    assert(res.status === 200, `Admin recording fee payment should succeed with 200, got ${res.status}`);
  });

  await test('102. Step 6: Student can read their own monthly fee record and payment entry', async () => {
    const monthRes = await getDoc(studentToken, `organizations/${orgId}/feeRecords/${studentUid}/months/2026-11`);
    assert(monthRes.status === 200, `Student reading own monthly fee doc should succeed with 200, got ${monthRes.status}`);

    const payRes = await getDoc(studentToken, `organizations/${orgId}/feeRecords/${studentUid}/months/2026-11/payments/pay_nov_01`);
    assert(payRes.status === 200, `Student reading own payment entry should succeed with 200, got ${payRes.status}`);
  });

  await test('103. Step 6: Student CANNOT modify or delete fee payment entry (strictly append-only)', async () => {
    const updateRes = await setDoc(studentToken, `organizations/${orgId}/feeRecords/${studentUid}/months/2026-11/payments/pay_nov_01`, {
      amount: 99999
    });
    assert(updateRes.status === 403, `Student updating payment entry must be rejected with 403, got ${updateRes.status}`);

    const delRes = await deleteDoc(studentToken, `organizations/${orgId}/feeRecords/${studentUid}/months/2026-11/payments/pay_nov_01`);
    assert(delRes.status === 403, `Student deleting payment entry must be rejected with 403, got ${delRes.status}`);
  });

  await test('104. Step 6: Teacher CANNOT access institute student fee records', async () => {
    const res = await getDoc(teacherVerifiedToken, `organizations/${orgId}/feeRecords/${studentUid}/months/2026-11`);
    assert(res.status === 403, `Teacher reading student fee record must be rejected with 403, got ${res.status}`);
  });

  await test('105. Step 6: Admin can create and manage teacher monthly salary record', async () => {
    const res = await setDoc(adminToken, `organizations/${orgId}/teacherSalaryRecords/${teacherUid}/months/2026-11`, {
      id: `${teacherUid}_2026-11`,
      org_id: orgId,
      teacher_uid: teacherUid,
      teacher_name: 'Jane Doe',
      amount: 45000.0,
      base_salary: 45000.0,
      amount_paid: 0.0,
      remaining_amount: 45000.0,
      month: '2026-11',
      status: 'pending'
    });
    assert(res.status === 200, `Admin creating teacher salary record should succeed with 200, got ${res.status}`);
  });

  await test('106. Step 6: Admin can record teacher salary payment entry', async () => {
    const res = await setDoc(adminToken, `organizations/${orgId}/teacherSalaryRecords/${teacherUid}/months/2026-11/payments/sal_pay_01`, {
      payment_id: 'sal_pay_01',
      amount: 45000.0,
      payment_method: 'bank_transfer',
      recorded_by: 'Institute Owner'
    });
    assert(res.status === 200, `Admin recording salary payment should succeed with 200, got ${res.status}`);
  });

  await test('107. Step 6: Teacher can read their own monthly salary record and payment entries', async () => {
    const salaryRes = await getDoc(teacherVerifiedToken, `organizations/${orgId}/teacherSalaryRecords/${teacherUid}/months/2026-11`);
    assert(salaryRes.status === 200, `Teacher reading own salary record should succeed with 200, got ${salaryRes.status}`);

    const payRes = await getDoc(teacherVerifiedToken, `organizations/${orgId}/teacherSalaryRecords/${teacherUid}/months/2026-11/payments/sal_pay_01`);
    assert(payRes.status === 200, `Teacher reading own salary payment should succeed with 200, got ${payRes.status}`);
  });

  await test('108. Step 6: Teacher CANNOT read another teacher\'s salary record or payments', async () => {
    const res = await getDoc(wrongEmailToken, `organizations/${orgId}/teacherSalaryRecords/${teacherUid}/months/2026-11`);
    assert(res.status === 403, `Teacher reading another teacher salary must be rejected with 403, got ${res.status}`);
  });

  await test('109. Step 6: Teacher CANNOT modify or delete salary payments (append-only protection)', async () => {
    const updateRes = await setDoc(teacherVerifiedToken, `organizations/${orgId}/teacherSalaryRecords/${teacherUid}/months/2026-11/payments/sal_pay_01`, {
      amount: 1000000
    });
    assert(updateRes.status === 403, `Teacher modifying salary payment must be rejected with 403, got ${updateRes.status}`);

    const delRes = await deleteDoc(teacherVerifiedToken, `organizations/${orgId}/teacherSalaryRecords/${teacherUid}/months/2026-11/payments/sal_pay_01`);
    assert(delRes.status === 403, `Teacher deleting salary payment must be rejected with 403, got ${delRes.status}`);
  });

  await test('110. Step 6: Cross-organization financial isolation: User from Institute A cannot access Institute B fees or salaries', async () => {
    const otherOrgId = 'org_competitor_888';
    const feeRes = await getDoc(adminToken, `organizations/${otherOrgId}/feeRecords/student_comp_01/months/2026-11`);
    assert(feeRes.status === 403, `Admin reading other org fee records must be rejected with 403, got ${feeRes.status}`);

    const salRes = await getDoc(adminToken, `organizations/${otherOrgId}/teacherSalaryRecords/teacher_comp_01/months/2026-11`);
    assert(salRes.status === 403, `Admin reading other org salary records must be rejected with 403, got ${salRes.status}`);
  });

  await test('111. Role Correction: Active Teacher can read all institute students regardless of batch', async () => {
    await setDoc(adminToken, `organizations/${orgId}/students/std_unassigned_99`, {
      id: 'std_unassigned_99',
      name: 'Unassigned Student',
      email: 'unassigned@test.com',
      batch: '',
      status: 'active'
    });

    const readRes = await getDoc(teacherVerifiedToken, `organizations/${orgId}/students/std_unassigned_99`);
    assert(readRes.status === 200, `Active teacher reading unassigned student must succeed with 200, got ${readRes.status}`);
  });

  await test('112. Role Correction: Suspended Teacher CANNOT read institute student data', async () => {
    const suspendedTeacherUid = 'teacher_suspended_999';
    const suspendedTeacherToken = makeJwt(suspendedTeacherUid, 'suspended@test.com', true);

    await setDoc(adminToken, `organizations/${orgId}/members/${suspendedTeacherUid}`, {
      uid: suspendedTeacherUid,
      email: 'suspended@test.com',
      name: 'Suspended Faculty',
      role: 'teacher',
      status: 'suspended'
    });

    const readRes = await getDoc(suspendedTeacherToken, `organizations/${orgId}/students/std_unassigned_99`);
    assert(readRes.status === 403, `Suspended teacher reading student must be rejected with 403, got ${readRes.status}`);
  });

  console.log('\n================================================================');
  console.log('FIRESTORE RULES EMULATOR SUITE TEST SUMMARY');
  console.log('================================================================');
  const passed = results.filter(r => r.pass).length;
  const failed = results.filter(r => !r.pass).length;
  console.log(`Total tests: ${results.length}`);
  console.log(`Passed: ${passed}`);
  console.log(`Failed: ${failed}`);
  if (failed > 0) {
    console.error('FAILED TESTS:');
    results.filter(r => !r.pass).forEach(r => console.error(` - ${r.name}: ${r.error}`));
    process.exit(1);
  } else {
    console.log('ALL FIRESTORE SECURITY RULES TESTS PASSED AGAINST EMULATOR!');
    process.exit(0);
  }
}

main().catch((err) => {
  console.error('Fatal test error:', err);
  process.exit(1);
});
