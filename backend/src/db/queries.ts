import { v4 as uuidv4 } from 'uuid';
import pool from './database.js';

/**
 * Data Access Layer for Flare Backend.
 * All functions use parameterized queries and handle JSON stringification/parsing.
 * Updated for PostgreSQL (async/await, $ placeholders).
 */

// --- USER QUERIES ---

export const createUser = async (user: any) => {
  const query = `
    INSERT INTO users (user_id, device_id, stellar_public_key, stellar_secret_key_encrypted, fcm_token, briefing_time, timezone, dnd_start, dnd_end, global_daily_cap)
    VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
  `;
  return pool.query(query, [
    user.userId, user.deviceId, user.stellarPublicKey, user.stellarSecretKeyEncrypted,
    user.fcmToken, user.briefingTime, user.timezone, user.dndStart, user.dndEnd, user.globalDailyCap
  ]);
};

export const getUserById = async (id: string) => {
  const res = await pool.query('SELECT * FROM users WHERE user_id = $1', [id]);
  return res.rows[0];
};

export const getAllUsers = async () => {
  const res = await pool.query('SELECT * FROM users');
  return res.rows;
};

export const getUserByDeviceId = async (deviceId: string) => {
  const res = await pool.query('SELECT * FROM users WHERE device_id = $1', [deviceId]);
  return res.rows[0];
};

export const updateUserFcmToken = async (userId: string, token: string) => {
  return pool.query('UPDATE users SET fcm_token = $1 WHERE user_id = $2', [token, userId]);
};

export const updateUser = async (id: string, fields: any) => {
  const keys = Object.keys(fields);
  if (keys.length === 0) return;
  const assignments = keys.map((key, i) => `${key} = $${i + 1}`).join(', ');
  const values = keys.map(key => fields[key]);
  const query = `UPDATE users SET ${assignments} WHERE user_id = $${keys.length + 1}`;
  return pool.query(query, [...values, id]);
};

// --- WATCHER QUERIES ---

export const createWatcher = async (watcher: any) => {
  const query = `
    INSERT INTO watchers (watcher_id, user_id, name, type, parameters, alert_conditions, check_interval_minutes, weekly_budget_usdc, priority, status)
    VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
  `;
  return pool.query(query, [
    watcher.watcherId, watcher.userId, watcher.name, watcher.type,
    JSON.stringify(watcher.parameters), JSON.stringify(watcher.alertConditions),
    watcher.checkIntervalMinutes, watcher.weeklyBudgetUsdc, watcher.priority, watcher.status
  ]);
};

export const getWatcherById = async (id: string) => {
  const res = await pool.query('SELECT * FROM watchers WHERE watcher_id = $1', [id]);
  const row = res.rows[0];
  if (row) {
    if (typeof row.parameters === 'string') row.parameters = JSON.parse(row.parameters);
    if (typeof row.alert_conditions === 'string') row.alert_conditions = JSON.parse(row.alert_conditions);
  }
  return row;
};

export const getWatchersByUserId = async (userId: string) => {
  const res = await pool.query('SELECT * FROM watchers WHERE user_id = $1', [userId]);
  return res.rows.map(row => ({
    ...row,
    parameters: typeof row.parameters === 'string' ? JSON.parse(row.parameters) : row.parameters,
    alert_conditions: typeof row.alert_conditions === 'string' ? JSON.parse(row.alert_conditions) : row.alert_conditions
  }));
};

export const updateWatcher = async (id: string, fields: any) => {
  // Filter out updated_at if it's already in fields to prevent duplicate assignment error
  const { updated_at, ...updateFields } = fields;
  const keys = Object.keys(updateFields);
  if (keys.length === 0) {
      // If only updated_at was provided, just update that timestamp
      return pool.query('UPDATE watchers SET updated_at = NOW() WHERE watcher_id = $1', [id]);
  }
  const assignments = keys.map((key, i) => `${key} = $${i + 1}`).join(', ');
  const values = keys.map(key => {
    if (key === 'parameters' || key === 'alert_conditions') return JSON.stringify(updateFields[key]);
    return updateFields[key];
  });
  const query = `UPDATE watchers SET ${assignments}, updated_at = NOW() WHERE watcher_id = $${keys.length + 1}`;
  return pool.query(query, [...values, id]);
};

export const deleteWatcher = async (id: string) => {
  return pool.query('DELETE FROM watchers WHERE watcher_id = $1', [id]);
};

export const getActiveWatchers = async () => {
    const res = await pool.query("SELECT * FROM watchers WHERE status = 'active'");
    return res.rows.map(row => ({
      ...row,
      parameters: typeof row.parameters === 'string' ? JSON.parse(row.parameters) : row.parameters,
      alert_conditions: typeof row.alert_conditions === 'string' ? JSON.parse(row.alert_conditions) : row.alert_conditions
    }));
};

// --- CHECK QUERIES ---

export const createCheck = async (check: any) => {
  const query = `
    INSERT INTO checks (check_id, watcher_id, user_id, service_name, request_payload, response_data, cost_usdc, stellar_tx_hash, finding_detected, finding_id, agent_reasoning, payment_method, channel_id)
    VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13)
  `;
  return pool.query(query, [
    check.checkId, check.watcherId, check.userId, check.serviceName,
    JSON.stringify(check.requestPayload), JSON.stringify(check.responseData),
    check.costUsdc, check.stellarTxHash, check.findingDetected, check.findingId, check.agentReasoning,
    check.paymentMethod || 'x402', check.channelId || null
  ]);
};

export const getChecksByWatcherId = async (watcherId: string, limit: number = 10, offset: number = 0) => {
  const res = await pool.query('SELECT * FROM checks WHERE watcher_id = $1 ORDER BY checked_at DESC LIMIT $2 OFFSET $3', [watcherId, limit, offset]);
  return res.rows.map(row => ({
    ...row,
    request_payload: typeof row.request_payload === 'string' ? JSON.parse(row.request_payload) : row.request_payload,
    response_data: typeof row.response_data === 'string' ? JSON.parse(row.response_data) : row.response_data
  }));
};

export const getChecksSince = async (userId: string, since: string) => {
  const res = await pool.query('SELECT * FROM checks WHERE user_id = $1 AND checked_at > $2', [userId, since]);
  return res.rows.map(row => ({
    ...row,
    request_payload: typeof row.request_payload === 'string' ? JSON.parse(row.request_payload) : row.request_payload,
    response_data: typeof row.response_data === 'string' ? JSON.parse(row.response_data) : row.response_data
  }));
};

// --- FINDING QUERIES ---

export const createFinding = async (finding: any) => {
  const query = `
    INSERT INTO findings (
      finding_id, watcher_id, check_id, user_id, type, 
      headline, detail, data, action_url, cost_usdc, 
      stellar_tx_hash, verified, verification_tx_hash, verification_check_id,
      collaboration_result, confidence_score, confidence_tier
    )
    VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17)
  `;
  
  const fId = (finding.finding_id && finding.finding_id.length > 0) ? finding.finding_id : (finding.findingId || uuidv4());
  
  return pool.query(query, [
    fId,
    finding.watcher_id || finding.watcherId, 
    finding.check_id || finding.checkId, 
    finding.user_id || finding.userId,
    finding.type, 
    finding.headline, 
    finding.detail, 
    JSON.stringify(finding.data),
    finding.action_url || finding.actionUrl || null, 
    finding.cost_usdc || finding.costUsdc || 0, 
    finding.stellar_tx_hash || finding.stellarTxHash || null,
    finding.verified || false,
    finding.verification_tx_hash || null,
    finding.verification_check_id || null,
    finding.collaboration_result ? JSON.stringify(finding.collaboration_result) : null,
    finding.confidence_score || 0,
    finding.confidence_tier || null
  ]);
};

export const getFindingById = async (id: string) => {
  const res = await pool.query('SELECT * FROM findings WHERE finding_id = $1', [id]);
  const row = res.rows[0];
  if (row && typeof row.data === 'string') row.data = JSON.parse(row.data);
  return row;
};

export const getFindingsByUserId = async (userId: string, limit: number = 50, offset: number = 0) => {
  const res = await pool.query(`
    SELECT f.*, w.name as watcher_name, w.type as watcher_type 
    FROM findings f
    JOIN watchers w ON f.watcher_id = w.watcher_id
    WHERE f.user_id = $1 
    ORDER BY f.found_at DESC LIMIT $2 OFFSET $3
  `, [userId, limit, offset]);
  return res.rows.map(row => ({ ...row, data: typeof row.data === 'string' ? JSON.parse(row.data) : row.data }));
};

export const getFindingDetail = async (id: string) => {
  const res = await pool.query(`
    SELECT f.*, w.name as watcher_name, w.type as watcher_type, c.checked_at as check_time, c.response_data as check_data
    FROM findings f
    JOIN watchers w ON f.watcher_id = w.watcher_id
    JOIN checks c ON f.check_id = c.check_id
    WHERE f.finding_id = $1
  `, [id]);
  const row = res.rows[0];
  if (row) {
    if (typeof row.data === 'string') row.data = JSON.parse(row.data);
    if (typeof row.check_data === 'string') row.check_data = JSON.parse(row.check_data);
  }
  return row;
};

export const getFindingsByWatcherId = async (watcherId: string) => {
  const res = await pool.query('SELECT * FROM findings WHERE watcher_id = $1 ORDER BY found_at DESC', [watcherId]);
  return res.rows.map(row => ({ ...row, data: typeof row.data === 'string' ? JSON.parse(row.data) : row.data }));
};

export const markFindingRead = async (id: string) => {
  return pool.query('UPDATE findings SET read = true WHERE finding_id = $1', [id]);
};

export const markFindingNotified = async (id: string) => {
  return pool.query('UPDATE findings SET notified = true WHERE finding_id = $1', [id]);
};

// --- BRIEFING QUERIES ---

export const createBriefing = async (briefing: any) => {
  const query = `
    INSERT INTO briefings (briefing_id, user_id, date, period_start, period_end, total_checks, total_findings, total_cost_usdc, findings_json, watcher_summaries_json, generated_summary)
    VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)
  `;
  return pool.query(query, [
    briefing.briefingId, briefing.userId, briefing.date, briefing.periodStart, briefing.periodEnd,
    briefing.totalChecks, briefing.totalFindings, briefing.totalCostUsdc,
    JSON.stringify(briefing.findingsJson), JSON.stringify(briefing.watcherSummariesJson), briefing.generatedSummary
  ]);
};

export const getBriefingsByUserId = async (userId: string, limit: number = 10) => {
  const res = await pool.query('SELECT * FROM briefings WHERE user_id = $1 ORDER BY generated_at DESC LIMIT $2', [userId, limit]);
  return res.rows.map(row => ({
    ...row,
    findings_json: typeof row.findings_json === 'string' ? JSON.parse(row.findings_json) : row.findings_json,
    watcher_summaries_json: typeof row.watcher_summaries_json === 'string' ? JSON.parse(row.watcher_summaries_json) : row.watcher_summaries_json
  }));
};

export const getTodayBriefing = async (userId: string) => {
    const today = new Date().toISOString().split('T')[0];
    const res = await pool.query('SELECT * FROM briefings WHERE user_id = $1 AND date = $2', [userId, today]);
    const row = res.rows[0];
    if (row) {
      if (typeof row.findings_json === 'string') row.findings_json = JSON.parse(row.findings_json);
      if (typeof row.watcher_summaries_json === 'string') row.watcher_summaries_json = JSON.parse(row.watcher_summaries_json);
    }
    return row;
};

export const getBriefingByDate = async (userId: string, date: string) => {
    const res = await pool.query('SELECT * FROM briefings WHERE user_id = $1 AND date = $2', [userId, date]);
    const row = res.rows[0];
    if (row) {
      if (typeof row.findings_json === 'string') row.findings_json = JSON.parse(row.findings_json);
      if (typeof row.watcher_summaries_json === 'string') row.watcher_summaries_json = JSON.parse(row.watcher_summaries_json);
    }
    return row;
};

// --- TRANSACTION QUERIES ---

export const createTransaction = async (tx: any) => {
  const query = `
    INSERT INTO transactions (tx_id, user_id, watcher_id, check_id, amount_usdc, service_name, stellar_tx_hash, tx_type, payment_method, channel_id)
    VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
  `;
  return pool.query(query, [
    tx.txId, tx.userId, tx.watcherId, tx.checkId || null, 
    tx.amountUsdc, tx.serviceName, tx.stellarTxHash, tx.txType || 'check',
    tx.paymentMethod || 'x402', tx.channelId || null
  ]);
};

export const getTransactionsByUserId = async (userId: string, limit: number = 20, offset: number = 0) => {
  const res = await pool.query(`
    SELECT t.*, w.name as watcher_name, c.finding_detected
    FROM transactions t
    LEFT JOIN watchers w ON t.watcher_id = w.watcher_id
    LEFT JOIN checks c ON t.check_id = c.check_id
    WHERE t.user_id = $1 
    ORDER BY t.timestamp DESC LIMIT $2 OFFSET $3
  `, [userId, limit, offset]);
  return res.rows;
};

export const getTransactionsByWatcherId = async (watcherId: string, limit: number = 20, offset: number = 0) => {
  const res = await pool.query(`
    SELECT t.*, c.finding_detected
    FROM transactions t
    LEFT JOIN checks c ON t.check_id = c.check_id
    WHERE t.watcher_id = $1 
    ORDER BY t.timestamp DESC LIMIT $2 OFFSET $3
  `, [watcherId, limit, offset]);
  return res.rows;
};

export const getSpendingStats = async (userId: string) => {
    const res = await pool.query(`
      SELECT 
        COALESCE(SUM(amount_usdc), 0) as total_spent,
        COALESCE(SUM(CASE WHEN timestamp >= date_trunc('day', NOW()) THEN amount_usdc ELSE 0 END), 0) as spent_today,
        COALESCE(SUM(CASE WHEN timestamp >= NOW() - INTERVAL '7 days' THEN amount_usdc ELSE 0 END), 0) as spent_this_week
      FROM transactions 
      WHERE user_id = $1
    `, [userId]);
    return res.rows[0];
};

export const getWalletAnalytics = async (userId: string) => {
  const dailySpendingRes = await pool.query(`
    SELECT date(timestamp) as date, SUM(amount_usdc) as amount
    FROM transactions
    WHERE user_id = $1 AND timestamp >= NOW() - INTERVAL '7 days'
    GROUP BY date(timestamp)
    ORDER BY date ASC
  `, [userId]);

  const perWatcherSpendingRes = await pool.query(`
    SELECT w.watcher_id, w.name as watcher_name, SUM(t.amount_usdc) as amount
    FROM transactions t
    JOIN watchers w ON t.watcher_id = w.watcher_id
    WHERE t.user_id = $1 AND t.timestamp >= date_trunc('week', NOW())
    GROUP BY w.watcher_id
  `, [userId]);

  const totalsRes = await pool.query(`
    SELECT 
      (SELECT COUNT(*) FROM checks WHERE user_id = $1 AND checked_at >= date_trunc('day', NOW())) as total_checks_today,
      (SELECT COUNT(*) FROM findings WHERE user_id = $2 AND found_at >= date_trunc('day', NOW())) as total_findings_today,
      (SELECT COUNT(*) FROM findings WHERE user_id = $3) as total_findings_all_time,
      (SELECT COALESCE(SUM(amount_usdc), 0) FROM transactions WHERE user_id = $4) as total_spent_all_time
  `, [userId, userId, userId, userId]);

  return {
    daily_spending: dailySpendingRes.rows,
    per_watcher_spending: perWatcherSpendingRes.rows,
    total_checks_today: Number(totalsRes.rows[0].total_checks_today),
    total_findings_today: Number(totalsRes.rows[0].total_findings_today),
    total_findings_all_time: Number(totalsRes.rows[0].total_findings_all_time),
    total_spent_all_time: totalsRes.rows[0].total_spent_all_time
  };
};

// --- NOTIFICATION QUERIES ---

export const createNotification = async (notification: any) => {
  const query = `
    INSERT INTO notifications (notification_id, user_id, title, body, type, data_id)
    VALUES ($1, $2, $3, $4, $5, $6)
  `;
  return pool.query(query, [
    notification.notification_id || uuidv4(),
    notification.user_id,
    notification.title,
    notification.body,
    notification.type,
    notification.data_id || null
  ]);
};

export const getNotificationsByUserId = async (userId: string, limit: number = 50, offset: number = 0) => {
  const res = await pool.query(
    'SELECT * FROM notifications WHERE user_id = $1 ORDER BY created_at DESC LIMIT $2 OFFSET $3',
    [userId, limit, offset]
  );
  return res.rows;
};

export const markNotificationRead = async (id: string, userId: string) => {
  return pool.query(
    'UPDATE notifications SET read = true WHERE notification_id = $1 AND user_id = $2',
    [id, userId]
  );
};

export const getUnreadNotificationCount = async (userId: string) => {
  const res = await pool.query(
    'SELECT COUNT(*) as unread_count FROM notifications WHERE user_id = $1 AND read = false',
    [userId]
  );
  return parseInt(res.rows[0].unread_count);
};
