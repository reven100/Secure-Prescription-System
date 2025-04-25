from cryptography.hazmat.primitives.asymmetric import rsa, padding
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.backends import default_backend
import base64

# Step 1: Key Generation (one-time per doctor)
def generate_keys():
    private_key = rsa.generate_private_key(public_exponent=65537, key_size=2048)
    public_key = private_key.public_key()
    return private_key, public_key

# Step 2: Doctor signs the prescription
def sign_prescription(prescription_text, private_key):
    prescription_bytes = prescription_text.encode('utf-8')
    signature = private_key.sign(
        prescription_bytes,
        padding.PSS(
            mgf=padding.MGF1(hashes.SHA256()),
            salt_length=padding.PSS.MAX_LENGTH
        ),
        hashes.SHA256()
    )
    return base64.b64encode(signature).decode('utf-8')  # Signature as a shareable string

# Step 3: Pharmacy verifies the prescription
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
        return True  # Valid Signature
    except Exception:
        return False  # Invalid or tampered

# -------------------------------
# Demonstration of Use Case Flow
# -------------------------------

# Generate keys for the doctor
private_key, public_key = generate_keys()

# Doctor writes a prescription
prescription = (
    "Patient: Ramesh | Drug: Amoxicillin 500mg | Qty: 5 tablets | "
    "Valid: 5 days | RX-ID: RX20250419001"
)

# Sign the prescription
signature = sign_prescription(prescription, private_key)

# Pharmacy verifies the received prescription
is_valid = verify_signature(prescription, signature, public_key)

# Output
print("Original Prescription:\n", prescription)
print("\nDigital Signature (Base64 Encoded):\n", signature)
print("\nVerification Result at Pharmacy:\n", "✅ Valid" if is_valid else "❌ Invalid")
