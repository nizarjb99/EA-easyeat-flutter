package com.example.ea_easyeat_flutter

import android.nfc.cardemulation.HostApduService
import android.os.Bundle

/**
 * HCE (Host Card Emulation) Service — Customer side
 *
 * Makes the customer's Android phone act as an NFC card.
 * When the employee's phone comes close and sends the SELECT AID command,
 * this service responds with the customer's ID.
 *
 * AID: F0394148148100 (proprietary, registered in apdu_service.xml)
 */
class HceService : HostApduService() {

    companion object {
        // Stored customer ID — set by MainActivity via setCustomerId()
        @Volatile
        var currentCustomerId: String? = null

        // AID: F0394148148100
        private val AID_BYTES = byteArrayOf(
            0xF0.toByte(), 0x39, 0x41, 0x48, 0x14, 0x81.toByte(), 0x00
        )

        // SELECT APDU: CLA=00, INS=A4, P1=04, P2=00, Lc=07, AID(7 bytes), Le=00
        private val SELECT_APDU_HEADER = byteArrayOf(0x00, 0xA4.toByte(), 0x04, 0x00)

        // GET DATA APDU: CLA=00, INS=CA, P1=01, P2=00
        private val GET_DATA_HEADER = byteArrayOf(0x00, 0xCA.toByte(), 0x01, 0x00)

        // Status words
        private val SW_OK = byteArrayOf(0x90.toByte(), 0x00)
        private val SW_UNKNOWN = byteArrayOf(0x00, 0x00)
    }

    override fun processCommandApdu(commandApdu: ByteArray, extras: Bundle?): ByteArray {
        if (commandApdu.size < 4) return SW_UNKNOWN

        return when {
            // Handle SELECT AID command
            isSelectCommand(commandApdu) -> {
                // Check AID matches
                if (commandApdu.size >= 4 + 1 + AID_BYTES.size) {
                    val receivedAid = commandApdu.copyOfRange(5, 5 + AID_BYTES.size)
                    if (receivedAid.contentEquals(AID_BYTES)) {
                        SW_OK
                    } else {
                        SW_UNKNOWN
                    }
                } else {
                    SW_UNKNOWN
                }
            }

            // Handle GET DATA command — returns the customer ID
            isGetDataCommand(commandApdu) -> {
                val id = currentCustomerId
                if (id != null && id.isNotEmpty()) {
                    val idBytes = id.toByteArray(Charsets.UTF_8)
                    idBytes + SW_OK
                } else {
                    SW_UNKNOWN
                }
            }

            else -> SW_UNKNOWN
        }
    }

    override fun onDeactivated(reason: Int) {
        // Called when NFC connection is lost — nothing to clean up here
    }

    private fun isSelectCommand(apdu: ByteArray): Boolean {
        return apdu.size >= 4 &&
            apdu[0] == SELECT_APDU_HEADER[0] &&
            apdu[1] == SELECT_APDU_HEADER[1] &&
            apdu[2] == SELECT_APDU_HEADER[2] &&
            apdu[3] == SELECT_APDU_HEADER[3]
    }

    private fun isGetDataCommand(apdu: ByteArray): Boolean {
        return apdu.size >= 4 &&
            apdu[0] == GET_DATA_HEADER[0] &&
            apdu[1] == GET_DATA_HEADER[1] &&
            apdu[2] == GET_DATA_HEADER[2] &&
            apdu[3] == GET_DATA_HEADER[3]
    }
}
