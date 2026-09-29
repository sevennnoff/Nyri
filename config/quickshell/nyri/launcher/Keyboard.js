.pragma library

const EN = "`qwertyuiop[]asdfghjkl;'zxcvbnm,./~{}:\"<>";
const RU = "ёйцукенгшщзхъфывапролджэячсмитьбю.ЁХЪЖЭБЮ";

const toRu = {}, toEn = {};
for (let i = 0; i < EN.length; i++) { toRu[EN[i]] = RU[i]; toEn[RU[i]] = EN[i]; }

function isCyr(ch) { return /[а-яё]/i.test(ch); }

function swap(q) {
    const cyr = [...q].filter(isCyr).length, lat = [...q].filter(c => /[a-z]/i.test(c)).length;
    const map = cyr > lat ? toEn : toRu;
    return [...q].map(c => map[c] ?? map[c.toLowerCase()] ?? c).join("");
}

const LAT = { а: "a", б: "b", в: "v", г: "g", д: "d", е: "e", ё: "e", ж: "zh", з: "z", и: "i", й: "y", к: "k", л: "l",
              м: "m", н: "n", о: "o", п: "p", р: "r", с: "s", т: "t", у: "u", ф: "f", х: "h", ц: "ts", ч: "ch", ш: "sh",
              щ: "sch", ъ: "", ы: "y", ь: "", э: "e", ю: "yu", я: "ya" };
const CYR = [["sch", "щ"], ["shch", "щ"], ["yo", "ё"], ["zh", "ж"], ["kh", "х"], ["ts", "ц"], ["ch", "ч"], ["sh", "ш"],
             ["yu", "ю"], ["ya", "я"], ["ph", "ф"], ["a", "а"], ["b", "б"], ["c", "к"], ["d", "д"], ["e", "е"], ["f", "ф"],
             ["g", "г"], ["h", "х"], ["i", "и"], ["j", "дж"], ["k", "к"], ["l", "л"], ["m", "м"], ["n", "н"], ["o", "о"],
             ["p", "п"], ["q", "к"], ["r", "р"], ["s", "с"], ["t", "т"], ["u", "у"], ["v", "в"], ["w", "в"], ["x", "кс"],
             ["y", "ы"], ["z", "з"]];

function latin(q) { return [...q].map(c => LAT[c] ?? c).join(""); }

function cyrillic(q) {
    let out = "", i = 0;
    while (i < q.length) {
        const hit = CYR.find(([l]) => q.startsWith(l, i));
        if (hit) { out += hit[1]; i += hit[0].length; }
        else { out += q[i]; i++; }
    }
    return out;
}

function variants(q) {
    const out = [{ text: q, cost: 0 }];
    const add = (text, cost) => { if (text && !out.some(v => v.text === text)) out.push({ text, cost }); };
    add(swap(q), 6);
    if ([...q].some(isCyr)) add(latin(q), 10);
    else add(cyrillic(q), 10);
    return out;
}

function best(vs, score) {
    let top = 0, from = 0;
    for (let i = 0; i < vs.length; i++) {
        const s = score(vs[i].text);
        if (s > 0 && s - vs[i].cost > top) { top = s - vs[i].cost; from = i; }
    }
    return { score: top, from };
}

function distance(a, b) {
    const d = [];
    for (let i = 0; i <= a.length; i++) { d.push([i]); }
    for (let j = 1; j <= b.length; j++) d[0][j] = j;
    for (let i = 1; i <= a.length; i++) {
        for (let j = 1; j <= b.length; j++) {
            const c = a[i - 1] === b[j - 1] ? 0 : 1;
            d[i][j] = Math.min(d[i - 1][j] + 1, d[i][j - 1] + 1, d[i - 1][j - 1] + c);
            if (i > 1 && j > 1 && a[i - 1] === b[j - 2] && a[i - 2] === b[j - 1]) d[i][j] = Math.min(d[i][j], d[i - 2][j - 2] + 1);
        }
    }
    return d[a.length][b.length];
}

function typo(q, text) {
    if (q.length < 3 || !text) return 0;
    const allowed = q.length <= 5 ? 1 : 2;
    let bestD = 99;
    for (const w of [text, ...text.split(/[\s\-_.]+/)]) {
        if (!w) continue;
        for (const n of [q.length - 1, q.length, q.length + 1]) {
            if (n < 2 || n > w.length) continue;
            bestD = Math.min(bestD, distance(q, w.slice(0, n)));
        }
    }
    return bestD <= allowed ? 34 - 8 * bestD : 0;
}
