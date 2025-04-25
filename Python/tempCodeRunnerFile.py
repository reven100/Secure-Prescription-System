from cryptography.hazmat.primitives.asymmetric import rsa, padding
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.backends import default_backend
import base64

# Generate RSA keys (For simulation: in practice, keys are stored and managed securely)
def generate_keys():
    private_key = rsa.generate_private_key(public_exponent=65537, key_size=2048)
    public_key = private_key.public_key()
    return private_key, public_key

# Function to sign a prescription using the doctor's private key
def sign_prescription(prescription_text, private_key):
    # Create a SHA-256 hash of the prescription
    prescription_bytes = prescription_text.encode('utf-8')
    signature = private_key.sign(
        prescription_bytes,
        padding.PSS(
            mgf=padding.MGF1(hashes.SHA256()),
            salt_length=padding.PSS.MAX_LENGTH
        ),
        hashes.SHA256()
    )
    return base64.b64encode(signature).decode('utf-8')  # Encode for easy sharing

# Function to verify a prescription's signature using the public key
def verify_signature(prescription_text, signature_b64, public_key):
    try:
        signature = base64.b64decode(signature_b64.encode('utf-8'))
        public_key.verify(
            signature,
            prescription_text.encode('utf-8'),
            padding.PSS(
                mgf=padding.MGF1(hashes.SHA256()),
                salt_length=padding.PSS.MAX_LENGTH
            ),
            hashes.SHA256()
        )
        return True  # Signature is valid
    except Exception as e:
        return False  # Signature invalid or tampered

# Simulating the process
private_key, public_key = generate_keys()

# Doctor creates a prescription
prescription = "Patient: Ramesh | Drug: Amoxicillin 500mg | Qty: 5 tablets | Valid: 5 days | RX-ID: RX20250419001"
signature = sign_prescription(prescription, private_key)

# Pharmacy receives and verifies the prescription
is_valid = verify_signature(prescription, signature, public_key)

(prescription, signature, is_valid)
