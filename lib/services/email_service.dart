import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

class EmailService {
  static final EmailService _instance = EmailService._internal();
  factory EmailService() => _instance;
  EmailService._internal();

  /// Checks if SMTP credentials are configured in .env
  bool get isSmtpConfigured {
    if (!dotenv.isInitialized) return false;
    final email = dotenv.env['SMTP_EMAIL']?.trim();
    final pass = dotenv.env['SMTP_PASSWORD']?.trim();
    return email != null && email.isNotEmpty && pass != null && pass.isNotEmpty;
  }

  /// Sends a verification code directly via SMTP to the recipient's inbox.
  Future<bool> sendVerificationEmail({
    required String recipientEmail,
    required String recipientName,
    required String verificationCode,
  }) async {
    if (!dotenv.isInitialized) return false;
    final senderEmail = dotenv.env['SMTP_EMAIL']?.trim();
    final senderPassword = dotenv.env['SMTP_PASSWORD']?.trim();

    if (senderEmail == null ||
        senderEmail.isEmpty ||
        senderPassword == null ||
        senderPassword.isEmpty) {
      debugPrint(
        'ℹ️ [EmailService] SMTP credentials not present in .env. Falling back to Supabase auth dispatch.',
      );
      return false;
    }

    try {
      final host = dotenv.env['SMTP_HOST']?.trim() ?? 'smtp.gmail.com';
      final port = int.tryParse(dotenv.env['SMTP_PORT']?.trim() ?? '') ?? 465;

      final smtpServer = SmtpServer(
        host,
        port: port,
        ssl: port == 465,
        username: senderEmail,
        password: senderPassword.replaceAll(' ', ''),
      );

      final message = Message()
        ..from = Address(senderEmail, 'DineQueue')
        ..recipients.add(recipientEmail.trim())
        ..subject = 'Your DineQueue Verification Code: $verificationCode'
        ..html = '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <title>DineQueue Verification Code</title>
</head>
<body style="margin: 0; padding: 24px; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; background-color: #0B1910; color: #FFFFFF;">
  <table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="max-width: 520px; margin: 0 auto; background-color: #122418; border-radius: 16px; border: 1px solid rgba(255,255,255,0.08); overflow: hidden;">
    <tr>
      <td style="padding: 32px 28px 20px 28px; text-align: center;">
        <h1 style="margin: 0; font-size: 26px; color: #F27B50; letter-spacing: -0.5px;">DineQueue</h1>
        <p style="margin: 6px 0 0 0; font-size: 13px; color: rgba(255,255,255,0.6);">Smart Queue & Dining Reservations</p>
      </td>
    </tr>
    <tr>
      <td style="padding: 0 28px 24px 28px;">
        <h2 style="margin: 0 0 12px 0; font-size: 18px; color: #FFFFFF;">Verify Your Customer Account</h2>
        <p style="margin: 0 0 20px 0; font-size: 14px; line-height: 1.5; color: rgba(255,255,255,0.8);">
          Hello <strong>$recipientName</strong>,<br>
          Thank you for creating an account with DineQueue. Use the verification code below to complete your registration:
        </p>
        <div style="background-color: #162C1E; border: 1.5px solid #F27B50; border-radius: 12px; padding: 20px; text-align: center; margin: 24px 0;">
          <span style="font-family: 'Courier New', Courier, monospace; font-size: 34px; font-weight: bold; letter-spacing: 10px; color: #F27B50; display: inline-block;">$verificationCode</span>
        </div>
        <p style="margin: 0 0 8px 0; font-size: 12px; color: rgba(255,255,255,0.6); text-align: center;">
          ⏱ This code will expire in <strong>10 minutes</strong>.
        </p>
        <p style="margin: 0; font-size: 12px; color: rgba(255,255,255,0.4); text-align: center;">
          This code is strictly valid for creating your new DineQueue customer account. If you did not request this code, you can safely ignore this email.
        </p>
      </td>
    </tr>
  </table>
</body>
</html>
''';

      final sendReport = await send(message, smtpServer);
      debugPrint(
        '✅ [EmailService] Direct SMTP email delivered to $recipientEmail: $sendReport',
      );
      return true;
    } catch (e) {
      debugPrint('⚠️ [EmailService] Direct SMTP delivery notice: $e');
      return false;
    }
  }
}
