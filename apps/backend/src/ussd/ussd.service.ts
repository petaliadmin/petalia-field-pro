import { Injectable, Logger } from '@nestjs/common';
import { UsersService } from '../users/users.service';
import { WalletService } from '../wallet/wallet.service';
import { SmsService } from '../common/services/sms.service';

@Injectable()
export class UssdService {
  private readonly logger = new Logger(UssdService.name);

  constructor(
    private readonly usersService: UsersService,
    private readonly walletService: WalletService,
    private readonly smsService: SmsService,
  ) {}

  async processUssdRequest(sessionId: string, phoneNumber: string, text: string): Promise<string> {
    this.logger.log(`[USSD SESSION] ID: ${sessionId} | Phone: ${phoneNumber} | Text: "${text}"`);

    const phone = phoneNumber.startsWith('+221') ? phoneNumber : `+221${phoneNumber.replace(/^7/, '7')}`;
    const user = await this.usersService.findByPhone(phone);

    if (!user) {
      return 'END Numéro non reconnu par Petalia. Veuillez vous inscrire auprès d\'un technicien agricole.';
    }

    if (text === '') {
      return `CON Bienvenue sur Petalia Crop Assist (${user.name || phone})\n1. Mon Solde de Crédits\n2. Synchroniser mon Application\n3. Recharger mon Compte`;
    }

    const parts = text.split('*');
    const firstChoice = parts[0];

    if (firstChoice === '1') {
      const balance = await this.walletService.getBalance(user.id);
      return `END Votre solde actuel est de ${balance} crédits agronomiques.`;
    }

    if (firstChoice === '2') {
      const balance = await this.walletService.getBalance(user.id);
      const syncPayload = `PETALIA:SYNC:BAL=${balance}:TS=${Date.now()}`;
      
      await this.smsService.sendSms(
        phone, 
        `Petalia Synchro: Votre solde officiel est de ${balance} crédits. Code de synchro app: [${syncPayload}]`
      );

      return `END Demande de synchronisation validée. Vous allez recevoir un SMS avec le code de synchronisation pour actualiser votre application mobile.`;
    }

    if (firstChoice === '3') {
      if (parts.length === 1) {
        return `CON Veuillez saisir le montant à recharger (ex: 500) :`;
      }

      const amountStr = parts[1];
      const amount = parseInt(amountStr, 10);

      if (isNaN(amount) || amount <= 0) {
        return `END Montant invalide. Session terminée.`;
      }

      await this.walletService.addCredits(user.id, amount, 'Recharge via USSD', `USSD_TOPUP_${sessionId}`);
      const newBalance = await this.walletService.getBalance(user.id);

      await this.smsService.sendSms(
        phone,
        `Petalia Recharge: +${amount} crédits ajoutés via USSD. Nouveau solde : ${newBalance} crédits.`
      );

      return `END Rechargement de ${amount} crédits effectué avec succès. Nouveau solde : ${newBalance} crédits.`;
    }

    return 'END Choix invalide. Au revoir.';
  }
}
