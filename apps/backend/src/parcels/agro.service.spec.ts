import { AgroService } from './agro.service';

describe('AgroService', () => {
  let service: AgroService;

  beforeEach(() => {
    service = new AgroService();
  });

  it('should return 1.0 for a recent visit without symptoms', () => {
    const lastVisit = new Date();
    expect(service.calculateHealthScore(lastVisit)).toBe(1.0);
  });

  it('should apply time penalty for visits older than 7 days', () => {
    const lastVisit = new Date();
    lastVisit.setDate(lastVisit.getDate() - 10); // 3 jours de retard
    const score = service.calculateHealthScore(lastVisit);
    expect(score).toBeLessThan(1.0);
    expect(score).toBeCloseTo(0.85, 1);
  });

  it('should apply severe penalty for "Mildiou"', () => {
    const lastVisit = new Date();
    const score = service.calculateHealthScore(lastVisit, ['Mildiou']);
    expect(score).toBe(0.7);
  });

  it('should return CRITICAL risk level for low scores', () => {
    expect(service.getRiskLevel(0.2)).toBe('CRITICAL');
  });
});
