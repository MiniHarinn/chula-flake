# Recapturing the RADIUS certificates

`radius-ca.pem` pins the ChulaWiFi and eduroam RADIUS certificates. Chula
publishes no PEM, so if one rotates, capture it off the air:

1. `nmcli device set <iface> managed no`
2. Run `wpa_supplicant -dd` with `ca_cert="probe://"`. It aborts before phase 2,
   so dummy credentials are fine. eduroam still needs an `@eduroam.chula.ac.th`
   identity to get an answer.
3. Rebuild the certificate from the RX EAPOL hexdumps in the log.
4. Confirm the sha256 from a second, independent capture before trusting it.

`ca-cert` takes several PEMs, so append rather than replace.
