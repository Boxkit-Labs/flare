import { Finding, WatcherRow } from '../types.js';

export interface ConfidenceResult {
  score: number;
  tier: 'Very High' | 'High' | 'Moderate' | 'Low' | 'Very Low';
  breakdown: {
    freshness: number;
    verification: number;
    history: number;
    collaboration: number;
    reliability: number;
  };
}

export class ConfidenceCalculator {

  public static calculate(
    watcher: WatcherRow,
    finding: Finding,
    checkTime: Date,
    hasHistory: boolean,
    collaborationResult: any
  ): ConfidenceResult {
    const breakdown = {
      freshness: this.calculateFreshness(checkTime),
      verification: this.calculateVerification(finding),
      history: this.calculateHistory(watcher, hasHistory),
      collaboration: this.calculateCollaboration(collaborationResult),
      reliability: this.calculateReliability(watcher)
    };

    const score = Object.values(breakdown).reduce((a, b) => a + b, 0);
    const tier = this.getTier(score);

    return { score, tier, breakdown };
  }

  private static calculateFreshness(checkTime: Date): number {
    const diffMs = new Date().getTime() - checkTime.getTime();
    const diffMin = diffMs / (1000 * 60);

    if (diffMin < 5) return 20;
    if (diffMin < 30) return 15;
    if (diffMin < 60) return 10;
    return 5;
  }

  private static calculateVerification(finding: Finding): number {
    if (finding.verified) return 25;
    return 10;
  }

  private static calculateHistory(watcher: WatcherRow, hasHistory: boolean): number {
    if (!hasHistory) return 10;

    return 20;
  }

  private static calculateCollaboration(collab: any): number {
    if (!collab) return 10;
    if (collab.safe === true) return 20;
    if (collab.safe === false) return 5;
    return 15;
  }

  private static calculateReliability(watcher: WatcherRow): number {

    if (watcher.type === 'news') return 8;
    if (watcher.type === 'custom') return 5;
    return 15;
  }

  private static getTier(score: number): any {
    if (score >= 90) return 'Very High';
    if (score >= 75) return 'High';
    if (score >= 60) return 'Moderate';
    if (score >= 40) return 'Low';
    return 'Very Low';
  }
}
