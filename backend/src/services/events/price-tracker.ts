import db from '../../db/database.js';
import { EventResult } from './types.js';

// ─── Interfaces ──────────────────────────────────────────────────────

export interface PriceDataPoint {
  historyId: number;
  watcherId: string;
  externalId: string;
  platform: string;
  tierName: string;
  minPrice: number;
  maxPrice: number;
  currency: string;
  available: boolean;
  quantityRemaining: number | null;
  quantityTotal: number | null;
  eventStatus: string;
  checkedAt: string;
}

export interface PriceTrend {
  tierName: string;
  currentMin: number;
  currentMax: number;
  previousMin: number | null;
  previousMax: number | null;
  allTimeLowest: number;
  allTimeHighest: number;
  changeAmount: number;
  changePercent: number;
  trend: 'rising' | 'falling' | 'stable';
  currency: string;
  snapshotCount: number;
}

export interface AvailabilityPoint {
  available: boolean;
  quantityRemaining: number | null;
  quantityTotal: number | null;
  checkedAt: string;
}

export interface CachedEvent {
  externalId: string;
  platform: string;
  name: string;
  venue: string | null;
  city: string | null;
  country: string | null;
  eventDate: string | null;
  imageUrl: string | null;
  eventUrl: string | null;
  isFree: boolean;
  category: string | null;
  updatedAt: string;
}

// ─── storePriceSnapshot ─────────────────────────────────────────────

export async function storePriceSnapshot(watcherId: string, event: EventResult): Promise<number> {
  let insertedCount = 0;

  for (const tier of event.ticketTiers) {
    await db.query(
      `INSERT INTO event_price_history 
        (watcher_id, external_id, platform, tier_name, min_price, max_price, currency, available, quantity_remaining, quantity_total, event_status, checked_at)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, NOW())`,
      [
        watcherId,
        event.id,
        event.platform,
        tier.name,
        tier.minPrice,
        tier.maxPrice,
        tier.currency,
        tier.available ? 1 : 0,
        tier.quantityRemaining ?? null,
        tier.quantityTotal ?? null,
        event.status
      ]
    );
    insertedCount++;
  }

  // Upsert event_cache
  await db.query(
    `INSERT INTO event_cache 
      (external_id, platform, name, venue, city, country, event_date, image_url, event_url, is_free, category, updated_at)
     VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, NOW())
     ON CONFLICT (external_id, platform) DO UPDATE SET
      name = EXCLUDED.name,
      venue = EXCLUDED.venue,
      city = EXCLUDED.city,
      country = EXCLUDED.country,
      event_date = EXCLUDED.event_date,
      image_url = EXCLUDED.image_url,
      event_url = EXCLUDED.event_url,
      is_free = EXCLUDED.is_free,
      category = EXCLUDED.category,
      updated_at = NOW()`,
    [
      event.id,
      event.platform,
      event.name,
      event.venueName,
      event.city,
      event.country,
      event.startDate,
      event.imageUrl ?? null,
      event.url,
      event.isFree,
      event.category
    ]
  );

  return insertedCount;
}

// ─── getPriceHistory ────────────────────────────────────────────────

export async function getPriceHistory(
  watcherId: string,
  tierName?: string,
  days: number = 30
): Promise<Record<string, PriceDataPoint[]>> {
  let query = `
    SELECT history_id, watcher_id, external_id, platform, tier_name,
           min_price, max_price, currency, available, quantity_remaining,
           quantity_total, event_status, checked_at
    FROM event_price_history
    WHERE watcher_id = $1
      AND checked_at >= NOW() - INTERVAL '1 day' * $2
  `;
  const params: any[] = [watcherId, days];

  if (tierName) {
    query += ` AND tier_name = $3`;
    params.push(tierName);
  }

  query += ` ORDER BY checked_at ASC`;

  const result = await db.query(query, params);

  const grouped: Record<string, PriceDataPoint[]> = {};
  for (const row of result.rows) {
    const point: PriceDataPoint = {
      historyId: row.history_id,
      watcherId: row.watcher_id,
      externalId: row.external_id,
      platform: row.platform,
      tierName: row.tier_name,
      minPrice: row.min_price,
      maxPrice: row.max_price,
      currency: row.currency,
      available: !!row.available,
      quantityRemaining: row.quantity_remaining,
      quantityTotal: row.quantity_total,
      eventStatus: row.event_status,
      checkedAt: row.checked_at
    };

    if (!grouped[point.tierName]) {
      grouped[point.tierName] = [];
    }
    grouped[point.tierName].push(point);
  }

  return grouped;
}

// ─── getPriceTrend ──────────────────────────────────────────────────

export async function getPriceTrend(
  watcherId: string,
  tierName: string
): Promise<PriceTrend | null> {
  // Get the two most recent snapshots
  const recentResult = await db.query(
    `SELECT min_price, max_price, currency
     FROM event_price_history
     WHERE watcher_id = $1 AND tier_name = $2
     ORDER BY checked_at DESC
     LIMIT 2`,
    [watcherId, tierName]
  );

  if (recentResult.rows.length === 0) return null;

  const latest = recentResult.rows[0];
  const previous = recentResult.rows.length > 1 ? recentResult.rows[1] : null;

  // Get all-time lowest and highest
  const extremesResult = await db.query(
    `SELECT MIN(min_price) as all_time_low, MAX(max_price) as all_time_high, COUNT(*) as snapshot_count
     FROM event_price_history
     WHERE watcher_id = $1 AND tier_name = $2`,
    [watcherId, tierName]
  );

  const extremes = extremesResult.rows[0];

  const currentMax = latest.max_price;
  const previousMax = previous ? previous.max_price : null;

  let changeAmount = 0;
  let changePercent = 0;

  if (previousMax !== null && previousMax > 0) {
    changeAmount = currentMax - previousMax;
    changePercent = (changeAmount / previousMax) * 100;
  }

  let trend: 'rising' | 'falling' | 'stable' = 'stable';
  if (changePercent > 1) trend = 'rising';
  else if (changePercent < -1) trend = 'falling';

  return {
    tierName,
    currentMin: latest.min_price,
    currentMax: latest.max_price,
    previousMin: previous ? previous.min_price : null,
    previousMax: previousMax,
    allTimeLowest: extremes.all_time_low,
    allTimeHighest: extremes.all_time_high,
    changeAmount: Math.round(changeAmount * 100) / 100,
    changePercent: Math.round(changePercent * 100) / 100,
    trend,
    currency: latest.currency,
    snapshotCount: parseInt(extremes.snapshot_count, 10)
  };
}

// ─── getAvailabilityHistory ─────────────────────────────────────────

export async function getAvailabilityHistory(
  watcherId: string,
  tierName: string,
  days: number = 30
): Promise<AvailabilityPoint[]> {
  const result = await db.query(
    `SELECT available, quantity_remaining, quantity_total, checked_at
     FROM event_price_history
     WHERE watcher_id = $1 AND tier_name = $2
       AND checked_at >= NOW() - INTERVAL '1 day' * $3
     ORDER BY checked_at ASC`,
    [watcherId, tierName, days]
  );

  return result.rows.map((row: any) => ({
    available: !!row.available,
    quantityRemaining: row.quantity_remaining,
    quantityTotal: row.quantity_total,
    checkedAt: row.checked_at
  }));
}

// ─── getEventFromCache ──────────────────────────────────────────────

export async function getEventFromCache(
  externalId: string,
  platform: string
): Promise<CachedEvent | null> {
  const result = await db.query(
    `SELECT external_id, platform, name, venue, city, country, event_date,
            image_url, event_url, is_free, category, updated_at
     FROM event_cache
     WHERE external_id = $1 AND platform = $2`,
    [externalId, platform]
  );

  if (result.rows.length === 0) return null;

  const row = result.rows[0];
  return {
    externalId: row.external_id,
    platform: row.platform,
    name: row.name,
    venue: row.venue,
    city: row.city,
    country: row.country,
    eventDate: row.event_date,
    imageUrl: row.image_url,
    eventUrl: row.event_url,
    isFree: !!row.is_free,
    category: row.category,
    updatedAt: row.updated_at
  };
}

// ─── cleanOldData ───────────────────────────────────────────────────

export async function cleanOldData(days: number = 90): Promise<number> {
  const result = await db.query(
    `DELETE FROM event_price_history
     WHERE checked_at < NOW() - INTERVAL '1 day' * $1`,
    [days]
  );

  return result.rowCount || 0;
}
