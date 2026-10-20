"""Reviewed Latin corrections; s + combining three dots denotes Arabic ث."""
import re

TH = 's\u20db'
KH_PARTS = (
    'hallis', 'hatî', 'hafiyy', 'hafıyy', 'hayr', 'hada’', 'mehâ', 'haşy',
    'hatây', 'hatâ', 'fahr', 'halik', 'hâlik', 'mahlûk', 'mahżûl', 'habîr',
    'sarîh', 'müstesrih', 'hâif', 'yuhâf', 'halk', 'yuâhiż', 'muahhir',
    'zühra', 'hâdi', 'hâşi', 'halaka', 'hâtı', 'yeftehir', 'yahlük',
    'yuhlâk', 'âhir', 'ahyâr', 'halâik', 'hazâin', 'halek', 'sehhara',
    'yettehiż', 'hîfet', 'şeyhi', 'yahtass', 'hazain', 'yahfâ', 'muhbit',
    'edhil', 'tahtime',
)
DH_WORDS = (
    'zâkir', 'Ze’', 'zelle', 'iznih', 'mahzûl', 'zünûb', 'müznib',
    'zenb', 'yuâhiz', 'Munzir', 'mezkûr', 'yünkiz', 'azâb', 'azab',
    'zikr', 'leziz', 'Muzellil', 'nefeze', 'yettehiz', 'züll', 'uzre',
    'Nezîr', 'llezî', 'Muzill', 'tezkirat', 'zerri', 'yü’azzib',
    'zekerah', 'Muzekkir', 'hâzihi', 'üstâzî',
)
CORRECTIONS = {
    (3, 5): [('vârişîn', 'vâri' + TH + 'în')],
    (4, 7): [('şevâb', TH + 'evâb')],
    (4, 9): [('sikâl', TH + 'ikâl')],
    (7, 8): [('Bâ’ise', 'Bâ’i' + TH + 'e')],
    (8, 0): [('senâ', TH + 'enâ')],
    (11, 6): [('Ğıyâşî', 'Ğıyâ' + TH + 'î')],
    (14, 1): [('Gıyâse', 'Gıyâ' + TH + 'e'), ('müsteğîsîn', 'müsteğî' + TH + 'în')],
    (28, 3): [('Giyâşe', 'Giyâ' + TH + 'e'), ('ğiyâşe', 'ğiyâ' + TH + 'e')],
    (30, 7): [('Muğîse', 'Muğî' + TH + 'e'), ('ğâseh', 'ğâ' + TH + 'eh')],
    (31, 2): [('Keşîra', 'Ke' + TH + 'îra')],
    (33, 5): [('Bâis', 'Bâi' + TH)],
    (33, 6): [('Vâris', 'Vâri' + TH)],
    (47, 9): [('mislehû', 'mi' + TH + 'lehû')],
    (52, 2): [('Muğîse', 'Muğî' + TH + 'e')],
    (53, 4): [('eşmâr', 'e' + TH + 'mâr')],
    (55, 0): [('meşelü', 'me' + TH + 'elü')],
    (55, 9): [('serâ', TH + 'erâ')],
    (57, 4): [('sümme', TH + 'ümme')],
    (58, 6): [('Muğîse', 'Muğî' + TH + 'e'), ('müğîse', 'müğî' + TH + 'e')],
    (63, 6): [('senâ', TH + 'enâ')],
    (63, 8): [('Keşira', 'Ke' + TH + 'ira')],
    (69, 3): [('kemislihî', 'kemi' + TH + 'lihî')],
    (70, 2): [('şenâün', TH + 'enâün')],
    (72, 7): [('Muğîs', 'Muğî' + TH)],
    (73, 8): [('misl', 'mi' + TH + 'l')],
    (75, 2): [('senâüh', TH + 'enâüh')],
    (86, 1): [('senaeh', TH + 'enaeh')],
    (89, 6): [('kemişlihî', 'kemi' + TH + 'lihî')],
    (90, 7): [('ğayşe', 'ğay' + TH + 'e')],
    (99, 3): [('sevâb', TH + 'evâb')],
    (100, 9): [('Muğisenâ', 'Muği' + TH + 'enâ')],
    (101, 1): [('senâen', TH + 'enâen'), ('esneyte', 'e' + TH + 'neyte')],
}


def correct_transcription(number, rows):
    if number == 31:
        rows[0]['tr'] = 'Yâ Kerîme’s-safhi'
    for (bab, row), replacements in CORRECTIONS.items():
        if bab == number:
            for old, new in replacements:
                rows[row]['tr'] = rows[row]['tr'].replace(old, new)
    for row in rows:
        if 'خ' in row['ar']:
            for part in KH_PARTS:
                row['tr'] = re.sub(re.escape(part), lambda match: match[0].replace('h', 'ḣ').replace('H', 'Ḣ'), row['tr'], flags=re.IGNORECASE)
        if 'ذ' in row['ar']:
            for word in DH_WORDS:
                row['tr'] = re.sub(re.escape(word), lambda match: match[0].replace('z', 'ż').replace('Z', 'Ż'), row['tr'], flags=re.IGNORECASE)
            # The assimilated article repeats the following dhal sound.
            row['tr'] = row['tr'].replace('z-ż', 'ż-ż')
        # In the reviewed source rows, plain g/G paired with غ denotes ghayn.
        if 'غ' in row['ar']:
            row['tr'] = row['tr'].replace('g', 'ğ').replace('G', 'Ğ')
        while '\u20db\u20db' in row['tr']:
            row['tr'] = row['tr'].replace('\u20db\u20db', '\u20db')
        row['tr'] = row['tr'].replace('ü', 'u').replace('Ü', 'U')
