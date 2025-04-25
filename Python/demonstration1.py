from cryptography.hazmat.primitives.asymmetric import rsa, padding
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.backends import default_backend
import base64
import qrcode

# Key Generation (Run once per doctor)
def generate_keys():
    private_key = rsa.generate_private_key(public_exponent=65537, key_size=2048)
    public_key = private_key.public_key()
    return private_key, public_key

# Signing Prescription
def sign_prescription(text, private_key):
    signature = private_key.sign(
        text.encode('utf-8'),
        padding.PSS(mgf=padding.MGF1(hashes.SHA256()), salt_length=padding.PSS.MAX_LENGTH),
        hashes.SHA256()
    )
    return base64.b64encode(signature).decode('utf-8')

# QR Code Generation
def generate_qr_code(data):
    qr = qrcode.make(data)
    qr.save("prescription_qr.png")
    
    
    
def verify_signature(text, signature_b64, public_key):
    try:
        signature = base64.b64decode(signature_b64.encode('utf-8'))
        public_key.verify(
            signature,
            text.encode('utf-8'),
            padding.PSS(mgf=padding.MGF1(hashes.SHA256()), salt_length=padding.PSS.MAX_LENGTH),
            hashes.SHA256()
        )
        return True  # Signature is valid
    except Exception:
        return False  # Tampering detected or invalid signature
