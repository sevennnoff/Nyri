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

const r0 = new Int32Array(64), r1 = new Int32Array(64), r2 = new Int32Array(64);

function distance(a, b, cap) {
    const n = Math.min(b.length, 62);
    let pp = r0, p = r1, c = r2;
    for (let j = 0; j <= n; j++) p[j] = j;
    for (let i = 1; i <= a.length; i++) {
        c[0] = i;
        let low = i;
        for (let j = 1; j <= n; j++) {
            let d = Math.min(p[j] + 1, c[j - 1] + 1, p[j - 1] + (a[i - 1] === b[j - 1] ? 0 : 1));
            if (i > 1 && j > 1 && a[i - 1] === b[j - 2] && a[i - 2] === b[j - 1] && pp[j - 2] + 1 < d) d = pp[j - 2] + 1;
            c[j] = d;
            if (d < low) low = d;
        }
        if (low > cap) return cap + 1;
        const t = pp; pp = p; p = c; c = t;
    }
    return p[n];
}

function terms(text) {
    return text ? [text, ...text.split(/[\s\-_.]+/)].filter(t => t) : [];
}

function typo(q, words) {
    if (q.length < 3) return 0;
    const allowed = q.length <= 5 ? 1 : 2;
    let bestD = allowed + 1;
    for (const w of words) {
        if (w.length < q.length - 1) continue;
        const head = w.slice(0, q.length + 1);
        let miss = 0;
        for (let i = 0; i < q.length && miss <= allowed; i++) if (head.indexOf(q[i]) < 0) miss++;
        if (miss > allowed) continue;
        for (let n = Math.max(2, q.length - 1); n <= Math.min(q.length + 1, w.length); n++) {
            const d = distance(q, w.slice(0, n), bestD - 1);
            if (d < bestD) bestD = d;
            if (!bestD) return 34;
        }
    }
    return bestD <= allowed ? 34 - 8 * bestD : 0;
}
