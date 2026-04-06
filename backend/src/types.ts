export interface WatcherRow {
  watcher_id: string;
  user_id: string;
  name: string;
  type: 'flight' | 'crypto' | 'news' | 'product' | 'job' | 'custom' | 'stock' | 'realestate' | 'sports';
  parameters: any;
  alert_conditions: any;
  check_interval_minutes: number;
  weekly_budget_usdc: number;
  spent_this_week_usdc: number;
  priority: 'low' | 'medium' | 'high';
  status: 'active' | 'paused_budget' | 'paused_manual' | 'paused_wallet' | 'error';
  error_message?: string;
  last_check_at?: string;
  next_check_at?: string;
}

export interface Finding {
  finding_id: string;
  watcher_id: string;
  check_id: string;
  user_id: string;
  type: 'price_drop' | 'price_spike' | 'threshold_crossed' | 'new_listing' | 'news_match';
  headline: string;
  detail: string;
  data: any;
  action_url?: string;
  cost_usdc: number;
  stellar_tx_hash?: string;
  agent_reasoning?: string;
  verified?: boolean;
  verification_tx_hash?: string;
  verification_check_id?: string;
  collaboration_result?: any;
  confidence_score?: number;
  confidence_tier?: string;
}
