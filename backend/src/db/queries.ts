import db from './database';

/**
 * Data Access Layer for Flare Backend.
 * All functions use parameterized queries and handle JSON stringification/parsing.
 */

// --- USER QUERIES ---

export const createUser = (user: any) => {
  const stmt = db.prepare(`
    INSERT INTO users (user_id, device_id, stellar_public_key, stellar_secret_key_encrypted, fcm_token, briefing_time, timezone, dnd_start, dnd_end, global_daily_cap)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
  `);
  return stmt.run(
    user.userId, user.deviceId, user.stellarPublicKey, user.stellarSecretKeyEncrypted,
    user.fcmToken, user.briefingTime, user.timezone, user.dndStart, user.dndEnd, user.globalDailyCap
  );
};

export const getUserById = (id: string) => {
  return db.prepare('SELECT * FROM users WHERE user_id = ?').get(id);
};

export const getUserByDeviceId = (deviceId: string) => {
  return db.prepare('SELECT * FROM users WHERE device_id = ?').get(deviceId);
};

export const updateUserFcmToken = (userId: string, token: string) => {
  return db.prepare('UPDATE users SET fcm_token = ? WHERE user_id = ?').run(token, userId);
};

// --- WATCHER QUERIES ---

export const createWatcher = (watcher: any) => {
  const stmt = db.prepare(`
    INSERT INTO watchers (watcher_id, user_id, name, type, parameters, alert_conditions, check_interval_minutes, weekly_budget_usdc, priority, status)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
  `);
  return stmt.run(
    watcher.watcherId, watcher.userId, watcher.name, watcher.type,
    JSON.stringify(watcher.parameters), JSON.stringify(watcher.alertConditions),
    watcher.checkIntervalMinutes, watcher.weeklyBudgetUsdc, watcher.priority, watcher.status
  );
};

export const getWatcherById = (id: string) => {
  const row: any = db.prepare('SELECT * FROM watchers WHERE watcher_id = ?').get(id);
  if (row) {
    row.parameters = JSON.parse(row.parameters);
    row.alert_conditions = JSON.parse(row.alert_conditions);
  }
  return row;
};

export const getWatchersByUserId = (userId: string) => {
  const rows: any[] = db.prepare('SELECT * FROM watchers WHERE user_id = ?').all(userId);
  return rows.map(row => ({
    ...row,
    parameters: JSON.parse(row.parameters),
    alert_conditions: JSON.parse(row.alert_conditions)
  }));
};

export const updateWatcher = (id: string, fields: any) => {
  const keys = Object.keys(fields);
  const assignments = keys.map(key => `${key} = ?`).join(', ');
  const values = keys.map(key => {
    if (key === 'parameters' || key === 'alert_conditions') return JSON.stringify(fields[key]);
    return fields[key];
  });
  const stmt = db.prepare(`UPDATE watchers SET ${assignments}, updated_at = datetime('now') WHERE watcher_id = ?`);
  return stmt.run(...values, id);
};

export const deleteWatcher = (id: string) => {
  return db.prepare('DELETE FROM watchers WHERE watcher_id = ?').run(id);
};

export const getActiveWatchers = () => {
    const rows: any[] = db.prepare("SELECT * FROM watchers WHERE status = 'active'").all();
    return rows.map(row => ({
      ...row,
      parameters: JSON.parse(row.parameters),
      alert_conditions: JSON.parse(row.alert_conditions)
    }));
};

// --- CHECK QUERIES ---

export const createCheck = (check: any) => {
  const stmt = db.prepare(`
    INSERT INTO checks (check_id, watcher_id, user_id, service_name, request_payload, response_data, cost_usdc, stellar_tx_hash, finding_detected, finding_id, agent_reasoning)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
  `);
  return stmt.run(
    check.checkId, check.watcherId, check.userId, check.serviceName,
    JSON.stringify(check.requestPayload), JSON.stringify(check.responseData),
    check.costUsdc, check.stellarTxHash, check.findingDetected ? 1 : 0, check.findingId, check.agentReasoning
  );
};

export const getChecksByWatcherId = (watcherId: string, limit: number = 10, offset: number = 0) => {
  const rows: any[] = db.prepare('SELECT * FROM checks WHERE watcher_id = ? ORDER BY checked_at DESC LIMIT ? OFFSET ?').all(watcherId, limit, offset);
  return rows.map(row => ({
    ...row,
    request_payload: JSON.parse(row.request_payload),
    response_data: JSON.parse(row.response_data)
  }));
};

export const getChecksSince = (userId: string, since: string) => {
  const rows: any[] = db.prepare('SELECT * FROM checks WHERE user_id = ? AND checked_at > ?').all(userId, since);
  return rows.map(row => ({
    ...row,
    request_payload: JSON.parse(row.request_payload),
    response_data: JSON.parse(row.response_data)
  }));
};

// --- FINDING QUERIES ---

export const createFinding = (finding: any) => {
  const stmt = db.prepare(`
    INSERT INTO findings (finding_id, watcher_id, check_id, user_id, type, headline, detail, data, action_url, cost_usdc, stellar_tx_hash)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
  `);
  return stmt.run(
    finding.findingId, finding.watcherId, finding.checkId, finding.userId,
    finding.type, finding.headline, finding.detail, JSON.stringify(finding.data),
    finding.actionUrl, finding.costUsdc, finding.stellarTxHash
  );
};

export const getFindingById = (id: string) => {
  const row: any = db.prepare('SELECT * FROM findings WHERE finding_id = ?').get(id);
  if (row) row.data = JSON.parse(row.data);
  return row;
};

export const getFindingsByUserId = (userId: string, limit: number = 50) => {
  const rows: any[] = db.prepare('SELECT * FROM findings WHERE user_id = ? ORDER BY found_at DESC LIMIT ?').all(userId, limit);
  return rows.map(row => ({ ...row, data: JSON.parse(row.data) }));
};

export const getFindingsByWatcherId = (watcherId: string) => {
  const rows: any[] = db.prepare('SELECT * FROM findings WHERE watcher_id = ? ORDER BY found_at DESC').all(watcherId);
  return rows.map(row => ({ ...row, data: JSON.parse(row.data) }));
};

export const markFindingRead = (id: string) => {
  return db.prepare('UPDATE findings SET read = 1 WHERE finding_id = ?').run(id);
};

// --- BRIEFING QUERIES ---

export const createBriefing = (briefing: any) => {
  const stmt = db.prepare(`
    INSERT INTO briefings (briefing_id, user_id, date, period_start, period_end, total_checks, total_findings, total_cost_usdc, findings_json, watcher_summaries_json, generated_summary)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
  `);
  return stmt.run(
    briefing.briefingId, briefing.userId, briefing.date, briefing.periodStart, briefing.periodEnd,
    briefing.totalChecks, briefing.totalFindings, briefing.totalCostUsdc,
    JSON.stringify(briefing.findingsJson), JSON.stringify(briefing.watcherSummariesJson), briefing.generatedSummary
  );
};

export const getBriefingsByUserId = (userId: string, limit: number = 10) => {
  const rows: any[] = db.prepare('SELECT * FROM briefings WHERE user_id = ? ORDER BY generated_at DESC LIMIT ?').all(userId, limit);
  return rows.map(row => ({
    ...row,
    findings_json: JSON.parse(row.findings_json),
    watcher_summaries_json: JSON.parse(row.watcher_summaries_json)
  }));
};

export const getTodayBriefing = (userId: string) => {
    const today = new Date().toISOString().split('T')[0];
    const row: any = db.prepare('SELECT * FROM briefings WHERE user_id = ? AND date = ?').get(userId, today);
    if (row) {
      row.findings_json = JSON.parse(row.findings_json);
      row.watcher_summaries_json = JSON.parse(row.watcher_summaries_json);
    }
    return row;
};

// --- TRANSACTION QUERIES ---

export const createTransaction = (tx: any) => {
  const stmt = db.prepare(`
    INSERT INTO transactions (tx_id, user_id, watcher_id, check_id, amount_usdc, service_name, stellar_tx_hash)
    VALUES (?, ?, ?, ?, ?, ?, ?)
  `);
  return stmt.run(tx.txId, tx.userId, tx.watcherId, tx.checkId || null, tx.amountUsdc, tx.serviceName, tx.stellarTxHash);
};

export const getTransactionsByUserId = (userId: string, limit: number = 20, offset: number = 0) => {
  return db.prepare('SELECT * FROM transactions WHERE user_id = ? ORDER BY timestamp DESC LIMIT ? OFFSET ?').all(userId, limit, offset);
};

export const getTransactionsByWatcherId = (watcherId: string) => {
  return db.prepare('SELECT * FROM transactions WHERE watcher_id = ? ORDER BY timestamp DESC').all(watcherId);
};

export const getSpendingStats = (userId: string) => {
    return db.prepare(`
      SELECT 
        SUM(amount_usdc) as total_spent,
        SUM(CASE WHEN timestamp >= date('now','start of day') THEN amount_usdc ELSE 0 END) as spent_today,
        SUM(CASE WHEN timestamp >= date('now','-7 days') THEN amount_usdc ELSE 0 END) as spent_this_week
      FROM transactions 
      WHERE user_id = ?
    `).get(userId);
};
