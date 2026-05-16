import { Injectable } from '@nestjs/common';
import { Parcel } from './entities/parcel.entity';

@Injectable()
export class DocumentService {
  generateParcelPassport(parcel: Parcel): string {
    const score = Math.round(parcel.healthScore * 100);

    return `
      <!DOCTYPE html>
      <html lang="fr">
        <head>
          <meta charset="UTF-8">
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
          <title>Passeport Petalia : ${parcel.name}</title>
          <style>
            body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif; background: #f0f2f5; margin: 0; padding: 20px; color: #1c1e21; }
            .card { background: white; max-width: 450px; margin: 20px auto; border-radius: 20px; overflow: hidden; box-shadow: 0 10px 25px rgba(0,0,0,0.08); }
            .header { background: #00703c; color: white; padding: 25px; text-align: center; }
            .header h1 { margin: 0; font-size: 24px; letter-spacing: -0.5px; }
            .content { padding: 25px; }
            .stat-row { display: flex; justify-content: space-between; padding: 12px 0; border-bottom: 1px solid #f0f2f5; }
            .stat-label { color: #65676b; font-size: 14px; }
            .stat-value { font-weight: 600; font-size: 15px; }
            .health-section { text-align: center; margin-top: 20px; background: #e8f5e9; padding: 20px; border-radius: 15px; }
            .health-score { font-size: 42px; font-weight: 800; color: #2e7d32; display: block; }
            .health-label { font-size: 13px; font-weight: 700; color: #1b5e20; text-transform: uppercase; letter-spacing: 1px; }
            .footer { padding: 20px; text-align: center; font-size: 12px; color: #bcc0c4; }
            .badge { display: inline-block; background: #ffd700; color: #000; padding: 4px 10px; border-radius: 5px; font-size: 10px; font-weight: 900; margin-bottom: 10px; }
          </style>
        </head>
        <body>
          <div class="card">
            <div class="header">
              <div class="badge">TRAÇABILITÉ VÉRIFIÉE</div>
              <h1>${parcel.name}</h1>
            </div>
            <div class="content">
              <div class="stat-row"><span class="stat-label">Exploitant</span><span class="stat-value">${parcel.owner}</span></div>
              <div class="stat-row"><span class="stat-label">Culture</span><span class="stat-value">${parcel.crop}</span></div>
              <div class="stat-row"><span class="stat-label">Village</span><span class="stat-value">${parcel.village || 'N/A'}</span></div>
              <div class="stat-row"><span class="stat-label">Dernière inspection</span><span class="stat-value">${parcel.lastVisit.toLocaleDateString('fr-FR')}</span></div>
              
              <div class="health-section">
                <span class="health-label">Indice de Santé Global</span>
                <span class="health-score">${score}%</span>
              </div>
            </div>
            <div class="footer">
              Généré par Petalia Field Pro &copy; 2026<br>Document authentique certifié par expertise agronomique.
            </div>
          </div>
        </body>
      </html>
    `;
  }
}
