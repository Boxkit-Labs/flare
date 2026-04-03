import crypto from 'node:crypto';

const ALGORITHM = 'aes-256-cbc';
const IV_LENGTH = 16; // For AES, this is always 16

/**
 * Encrypts cleartext using AES-256-CBC.
 * Uses the ENCRYPTION_KEY from environment variables.
 * Prepends the IV to the ciphertext, separated by a colon.
 * @param text The text to encrypt.
 * @param key Hex-encoded 32-byte encryption key.
 * @returns Encrypted string in format 'iv:ciphertext' (hex).
 */
export function encrypt(text: string, key: string): string {
    const iv = crypto.randomBytes(IV_LENGTH);
    const cipher = crypto.createCipheriv(ALGORITHM, Buffer.from(key, 'hex'), iv);
    let encrypted = cipher.update(text);
    encrypted = Buffer.concat([encrypted, cipher.final()]);
    return iv.toString('hex') + ':' + encrypted.toString('hex');
}

/**
 * Decrypts a 'iv:ciphertext' string back to cleartext.
 * @param encryptedText The encrypted hex string.
 * @param key Hex-encoded 32-byte encryption key.
 * @returns Original decrypted string.
 */
export function decrypt(encryptedText: string, key: string): string {
    const textParts = encryptedText.split(':');
    const iv = Buffer.from(textParts.shift()!, 'hex');
    const encryptedData = Buffer.from(textParts.join(':'), 'hex');
    const decipher = crypto.createDecipheriv(ALGORITHM, Buffer.from(key, 'hex'), iv);
    let decrypted = decipher.update(encryptedData);
    decrypted = Buffer.concat([decrypted, decipher.final()]);
    return decrypted.toString();
}
