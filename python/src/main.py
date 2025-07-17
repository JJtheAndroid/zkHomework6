
from py_ecc.bn128 import G2  # BN128 is often used interchangeably with BN254/BN256 in Ethereum context
from py_ecc.bn128 import G1, add, multiply, pairing 

# G2 is represented as a tuple of two Fp2 elements.
# Each Fp2 element is a tuple of two Fp (finite field) elements.
# So, G2 = ((x_real, x_imag), (y_real, y_imag))
# where x_real, x_imag, y_real, y_imag are large integers.

print("G1 Point time 5:")
print (multiply(G1, 5))



print("G2 Point times 8:")
print (multiply(G2, 8))
