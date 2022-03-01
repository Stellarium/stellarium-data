
from PyQt5.QtCore import QDataStream, QIODevice, QFile
import math
import re

otypeMap = {"G": "Nebula::NebGx",
"GX": "Nebula::NebGx",
"GC": "Nebula::NebGc",
"OC": "Nebula::NebOc",
"NB": "Nebula::NebN",
"PN": "Nebula::NebPn",
"DN": "Nebula::NebDn",
"RN": "Nebula::NebRn",
"C+N": "Nebula::NebCn",
"RNE": "Nebula::NebRn",
"HII": "Nebula::NebHII",
"SNR": "Nebula::NebSNR",
"BN": "Nebula::NebBn",
"EN": "Nebula::NebEn",
"SA": "Nebula::NebSA",
"SC": "Nebula::NebSC",
"CL": "Nebula::NebCl",
"IG": "Nebula::NebIGx",
"RG": "Nebula::NebRGx",
"AGX": "Nebula::NebAGx",
"QSO": "Nebula::NebQSO",
"ISM": "Nebula::NebISM",
"EMO": "Nebula::NebEMO",
"GNE": "Nebula::NebHII",
"RAD": "Nebula::NebISM",
"LIN": "Nebula::NebAGx",
"BLL": "Nebula::NebBLL",
"BLA": "Nebula::NebBLA",
"MOC": "Nebula::NebMolCld",
"YSO": "Nebula::NebYSO",
"Q?": "Nebula::NebPossQSO",
"PN?": "Nebula::NebPossPN",
"*": "Nebula::NebStar",
"SFR": "Nebula::NebMolCld",
"IR": "Nebula::NebDn",
"**": "Nebula::NebStar",
"MUL": "Nebula::NebStar",
"PPN": "Nebula::NebPPN",
"GIG": "Nebula::NebIGx",
"OPC": "Nebula::NebOc",
"MGR": "Nebula::NebSA",
"IG2": "Nebula::NebIGx",
"IG3": "Nebula::NebIGx",
"SY*": "Nebula::NebSymbioticStar",
"PA*": "Nebula::NebPPN",
"CV*": "Nebula::NebStar",
"Y*?": "Nebula::NebYSO",
"CGB": "Nebula::NebISM",
"SNRG": "Nebula::NebSNR",
"Y*O": "Nebula::NebYSO",
"SR*": "Nebula::NebStar",
"EM*": "Nebula::NebEmissionLineStar",
"AB*": "Nebula::NebStar",
"MI*": "Nebula::NebStar",
"MI?": "Nebula::NebStar",
"TT*": "Nebula::NebStar",
"WR*": "Nebula::NebStar",
"C*": "Nebula::NebEmissionLineStar",
"WD*": "Nebula::NebStar",
"EL*": "Nebula::NebStar",
"NL*": "Nebula::NebStar",
"NO*": "Nebula::NebStar",
"HS*": "Nebula::NebStar",
"LP*": "Nebula::NebStar",
"OH*": "Nebula::NebStar",
"S?R": "Nebula::NebStar",
"IR*": "Nebula::NebStar",
"POC": "Nebula::NebMolCld",
"PNB": "Nebula::NebPn",
"GXCL": "Nebula::NebGxCl",
"AL*": "Nebula::NebStar",
"PR*": "Nebula::NebStar",
"RS*": "Nebula::NebStar",
"S*B": "Nebula::NebStar",
"SN?": "Nebula::NebSNC",
"SR?": "Nebula::NebSNRC",
"DNE": "Nebula::NebDn",
"RG*": "Nebula::NebStar",
"PSR": "Nebula::NebSNR",
"HH": "Nebula::NebISM",
"V*": "Nebula::NebStar",
"*IN": "Nebula::NebCn",
"SN*": "Nebula::NebStar",
"PA?": "Nebula::NebPPN",
"BUB": "Nebula::NebISM",
"CLG": "Nebula::NebGxCl",
"POG": "Nebula::NebPartOfGx",
"CGG": "Nebula::NebGxCl",
"SCG": "Nebula::NebGxCl",
"REG": "Nebula::NebRegion",
"?": "Nebula::NebUnknown"
}
otypedic = {
"G": 0,
"GX": 0,
"GC": 7,
"OC": 6,
"NB": 10,
"PN": 11,
"DN": 12,
"RN": 13,
"C+N": 16,
"RNE": 13,
"HII": 17,
"SNR": 18,
"BN": 14,
"EN": 15,
"SA": 8,
"SC": 9,
"CL": 5,
"IG": 3,
"RG": 2,
"AGX": 1,
"QSO": 4,
"ISM": 19,
"EMO": 20,
"GNE": 17,
"RAD": 19,
"LIN": 1,
"BLL": 21,
"BLA": 22,
"MOC": 23,
"YSO": 24,
"Q?": 25,
"PN?": 26,
"*": 28,
"SFR": 23,
"IR": 12,
"**": 28,
"MUL": 28,
"PPN": 27,
"GIG": 3,
"OPC": 6,
"MGR": 8,
"IG2": 3,
"IG3": 3,
"SY*": 29,
"PA*": 27,
"CV*": 28,
"Y*?": 24,
"CGB": 19,
"SNRG": 18,
"Y*O": 24,
"SR*": 28,
"EM*": 30,
"AB*": 28,
"MI*": 28,
"MI?": 28,
"TT*": 28,
"WR*": 28,
"C*": 30,
"WD*": 28,
"EL*": 28,
"NL*": 28,
"NO*": 28,
"HS*": 28,
"LP*": 28,
"OH*": 28,
"S?R": 28,
"IR*": 28,
"POC": 23,
"PNB": 11,
"GXCL": 33,
"AL*": 28,
"PR*": 28,
"RS*": 28,
"S*B": 28,
"SN?": 31,
"SR?": 32,
"DNE": 12,
"RG*": 28,
"PSR": 18,
"HH": 19,
"V*": 28,
"*IN": 16,
"SN*": 28,
"PA?": 27,
"BUB": 19,
"CLG": 33,
"POG": 34,
"CGG": 33,
"SCG": 33,
"REG": 35,
"?": 36
}

# convert catalog.txt to catalog.pack

def ConverttxtToPack(in1,out1):
    dsoIn = QFile(in1)
    if dsoIn.open(QIODevice.ReadOnly | QIODevice.Text) is False:
        return
    dsoOut=QFile(out1)
    if dsoOut.open(QIODevice.WriteOnly) is False:
        return
    
    totalRecords = 0
    while (dsoIn.atEnd() is False):
        dsoIn.readLine()
        totalRecords+=1
    dsoIn.seek(0)
    dsoOutStream = QDataStream(dsoOut)
    dsoOutStream.setVersion(QDataStream.Qt_5_2)
    readOk = 0

    addedHead=False

    while (dsoIn.atEnd() is False):
        record = str(dsoIn.readLine(), encoding='utf-8')
        vp = re.match("^.*ersion\s+([\d\.]+)\s+(\w+)",record)

        if vp:
            print(vp.group(1),vp.group(2))
            dsoOutStream.writeQString(vp.group(1))
            dsoOutStream.writeQString(vp.group(2))
            addedHead=True

        if (record.startswith("//") or record.startswith("#")):
            totalRecords-=1
            continue
        
        # write when could not get label from txt
        if not addedHead:
            dsoOutStream.writeQString('3.13')
            dsoOutStream.writeQString('standard')
            addedHead=True

        lis=record.split('\t')
        
        if 1:
            id = int(lis[0] if lis[0]!="" else 0)
            ra = float((lis[1]).strip())
            dec = float((lis[2]).strip())
            bMag = float(lis[3])
            vMag = float(lis[4])
            oType = (lis[5]).strip() #
            mType = (lis[6]).strip() #
            majorAxisSize = float(lis[7])
            minorAxisSize = float(lis[8])
            orientationAngle = int(float(lis[9]) if float(lis[9])!="" else 0)
            z = float(lis[10])
            zErr = float(lis[11])
            plx = float(lis[12])
            plxErr = float(lis[13])
            dist = float(lis[14])
            distErr = float(lis[15])
            NGC = int(lis[16] if lis[16]!="" else 0)
            IC = int(lis[17] if lis[17]!="" else 0)
            M = int(lis[18] if lis[18]!="" else 0)
            C = int(lis[19] if lis[19]!="" else 0)
            B = int(lis[20] if lis[20]!="" else 0)
            Sh2 = int(lis[21] if lis[21]!="" else 0)
            VdB = int(lis[22] if lis[22]!="" else 0)
            RCW = int(lis[23] if lis[23]!="" else 0)
            LDN = int(lis[24] if lis[24]!="" else 0)
            LBN = int(lis[25] if lis[25]!="" else 0)
            Cr = int(lis[26] if lis[26]!="" else 0)
            Mel = int(lis[27] if lis[27]!="" else 0)
            PGC = int(lis[28] if lis[28]!="" else 0)
            UGC = int(lis[29] if lis[29]!="" else 0)
            Ced = (lis[30]).strip() #
            Arp = int(lis[31] if lis[31]!="" else 0)
            VV = int(lis[32] if lis[32]!="" else 0)
            PK = (lis[33]).strip() #
            PNG = (lis[34]).strip() #
            SNRG = (lis[35]).strip() #
            ACO = (lis[36]).strip() #
            HCG = (lis[37]).strip() #
            ESO = (lis[38]).strip() #
            VdBH = (lis[39]).strip() #
            DWB = int(lis[40] if lis[40]!="" else 0)
            Tr = int(lis[41] if lis[41]!="" else 0)
            St = int(lis[42] if lis[42]!="" else 0)
            Ru = int(lis[43] if lis[43]!="" else 0)
            VdBHa = int(lis[44] if lis[44]!="" else 0)


            raRad = float(ra) * math.pi / 180
            decRad = float(dec) * math.pi / 180
            majorAxisSize /= 60
            minorAxisSize /= 60
            if (bMag <= 0):
                bMag = 99
            if (vMag <= 0):
                vMag = 99
            
            if oType.upper() in otypedic:
                nType = otypedic[oType.upper()]
            else:
                nType = 36
            
            readOk += 1
            dsoOutStream.writeInt(id)
            dsoOutStream.writeFloat(raRad)
            dsoOutStream.writeFloat(decRad)
            dsoOutStream.writeFloat(bMag)
            dsoOutStream.writeFloat(vMag)
            dsoOutStream.writeInt(nType)
            dsoOutStream.writeQString(mType)
            dsoOutStream.writeFloat(majorAxisSize)
            dsoOutStream.writeFloat(minorAxisSize)
            dsoOutStream.writeInt(orientationAngle)
            dsoOutStream.writeFloat(z)
            dsoOutStream.writeFloat(zErr)
            dsoOutStream.writeFloat(plx)
            dsoOutStream.writeFloat(plxErr)
            dsoOutStream.writeFloat(dist)
            dsoOutStream.writeFloat(distErr)
            dsoOutStream.writeInt(NGC)
            dsoOutStream.writeInt(IC)
            dsoOutStream.writeInt(M)
            dsoOutStream.writeInt(C)
            dsoOutStream.writeInt(B)
            dsoOutStream.writeInt(Sh2)
            dsoOutStream.writeInt(VdB)
            dsoOutStream.writeInt(RCW)
            dsoOutStream.writeInt(LDN)
            dsoOutStream.writeInt(LBN)
            dsoOutStream.writeInt(Cr)
            dsoOutStream.writeInt(Mel)
            dsoOutStream.writeInt(PGC)
            dsoOutStream.writeInt(UGC)
            dsoOutStream.writeQString(Ced)
            dsoOutStream.writeInt(Arp)
            dsoOutStream.writeInt(VV)
            dsoOutStream.writeQString(PK)
            dsoOutStream.writeQString(PNG)
            dsoOutStream.writeQString(SNRG)
            dsoOutStream.writeQString(ACO)
            dsoOutStream.writeQString(HCG)
            dsoOutStream.writeQString(ESO)
            dsoOutStream.writeQString(VdBH)
            dsoOutStream.writeInt(DWB)
            dsoOutStream.writeInt(Tr)
            dsoOutStream.writeInt(St)
            dsoOutStream.writeInt(Ru)
            dsoOutStream.writeInt(VdBHa)
    dsoIn.close()
    dsoOut.flush()
    dsoOut.close()
    return

# write lines to text file

def writealllines(lines,src,srccoding="utf-8",crlf=True,EOF=False,mixCRLF=False):
    if mixCRLF:
        fp=open(src,"wb")
        for it in lines:
            fp.write(it.encode(srccoding))
        return
    rf = ('\n' if crlf == True else '')
    fp = open(src, "w", encoding=srccoding)
    lis=[lines[i] + rf if i<len(lines)-1 or EOF else lines[i] for i in range(len(lines))]
    fp.writelines(lis)
    fp.write("")
    fp.close()


# convert catalog.pack to catalog.txt

def decodePack2Txt(in1,out1,dem='\t'):
    dsoIn = QFile(in1)
    if dsoIn.open(QIODevice.ReadOnly) is False:
        return

    OTdic={}
    for it in otypedic:
        if str(otypedic[it]) not in OTdic:
            OTdic[str(otypedic[it])]=it

    dsoIn.seek(0)
    dsoInStream = QDataStream(dsoIn)
    dsoInStream.setVersion(QDataStream.Qt_5_2)
    print(dsoInStream.readQString())
    print(dsoInStream.readQString())
    lines=[]
    while dsoIn.atEnd() is False:
        id=dsoInStream.readInt()
        raRad=dsoInStream.readFloat()
        decRad=dsoInStream.readFloat()
        bMag=dsoInStream.readFloat()
        vMag=dsoInStream.readFloat()
        nType=dsoInStream.readInt()
        mType=dsoInStream.readQString()
        majorAxisSize=dsoInStream.readFloat()
        minorAxisSize=dsoInStream.readFloat()
        orientationAngle=dsoInStream.readInt()
        z=dsoInStream.readFloat()
        zErr=dsoInStream.readFloat()
        plx=dsoInStream.readFloat()
        plxErr=dsoInStream.readFloat()
        dist=dsoInStream.readFloat()
        distErr=dsoInStream.readFloat()
        NGC=dsoInStream.readInt()
        IC=dsoInStream.readInt()
        M=dsoInStream.readInt()
        C=dsoInStream.readInt()
        B=dsoInStream.readInt()
        Sh2=dsoInStream.readInt()
        VdB=dsoInStream.readInt()
        RCW=dsoInStream.readInt()
        LDN=dsoInStream.readInt()
        LBN=dsoInStream.readInt()
        Cr=dsoInStream.readInt()
        Mel=dsoInStream.readInt()
        PGC=dsoInStream.readInt()
        UGC=dsoInStream.readInt()
        Ced=dsoInStream.readQString()
        Arp=dsoInStream.readInt()
        VV=dsoInStream.readInt()
        PK=dsoInStream.readQString()
        PNG=dsoInStream.readQString()
        SNRG=dsoInStream.readQString()
        ACO=dsoInStream.readQString()
        HCG=dsoInStream.readQString()
        ESO=dsoInStream.readQString()
        VdBH=dsoInStream.readQString()
        DWB=dsoInStream.readInt()
        Tr=dsoInStream.readInt()
        St=dsoInStream.readInt()
        Ru=dsoInStream.readInt()
        VdBHa=dsoInStream.readInt()


        ra = float(raRad  * 180 / math.pi)
        dec = float(decRad * 180 / math.pi)
        majorAxisSize *= 60
        minorAxisSize *= 60
        
        if str(nType) in OTdic:
            oType=OTdic[str(nType)]
        
        lis=[id, ra, dec, bMag, vMag, oType, mType, majorAxisSize, minorAxisSize, orientationAngle, z, zErr, plx, plxErr, dist, distErr, 
        NGC, IC, M, C, B, Sh2, VdB, RCW, LDN, LBN, Cr, Mel, PGC, UGC, Ced, Arp, VV, PK, PNG, SNRG, ACO, HCG, ESO, VdBH, DWB, Tr, St, Ru, VdBHa]

        lis=list(str(x) for x in lis)
        lines.append(dem.join(lis))
    writealllines(lines,out1)


if __name__ == '__main__':
    src="catalog.txt"
    dst="catalog.pack"
    ConverttxtToPack(src, dst)
    
    # dst2="catalog1.txt"
    # decodePack2Txt(dst, dst2)
