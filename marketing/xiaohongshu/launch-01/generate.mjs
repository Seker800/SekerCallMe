import { execFileSync } from "node:child_process";
import { readFileSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const dir = dirname(fileURLToPath(import.meta.url));
const W = 1080;
const H = 1440;
const hero = `data:image/png;base64,${readFileSync(join(dir, "hero.png")).toString("base64")}`;

const C = {
  ink: "#17171C",
  paper: "#F5F2EB",
  white: "#FFFFFF",
  purple: "#8B5CF6",
  blue: "#2563EB",
  orange: "#F97316",
  muted: "#706C78",
  soft: "#E9E4DA",
};

const defs = `
  <defs>
    <linearGradient id="brand" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0" stop-color="${C.purple}"/><stop offset="1" stop-color="${C.blue}"/>
    </linearGradient>
    <linearGradient id="darkFade" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#0D0D13" stop-opacity=".90"/>
      <stop offset=".5" stop-color="#0D0D13" stop-opacity=".30"/>
      <stop offset="1" stop-color="#0D0D13" stop-opacity=".93"/>
    </linearGradient>
    <filter id="shadow" x="-20%" y="-20%" width="140%" height="140%">
      <feDropShadow dx="0" dy="18" stdDeviation="24" flood-color="#111827" flood-opacity=".16"/>
    </filter>
    <clipPath id="roundPhoto"><rect x="72" y="176" width="936" height="430" rx="36"/></clipPath>
  </defs>`;

function base(bg = C.paper) {
  return `<svg xmlns="http://www.w3.org/2000/svg" width="${W}" height="${H}" viewBox="0 0 ${W} ${H}">${defs}<rect width="${W}" height="${H}" fill="${bg}"/>`;
}

function text(x, y, value, size, weight = 700, fill = C.ink, anchor = "start", extra = "") {
  return `<text x="${x}" y="${y}" font-family="PingFang SC, Hiragino Sans GB, Arial, sans-serif" font-size="${size}" font-weight="${weight}" fill="${fill}" text-anchor="${anchor}" ${extra}>${value}</text>`;
}

function brand(x, y, scale = 1, light = false) {
  const word = light ? C.white : C.ink;
  return `<g transform="translate(${x} ${y}) scale(${scale})">
    <rect width="76" height="76" rx="19" fill="url(#brand)"/>
    <path d="M20 20h28c8 0 14 6 14 14v8c0 8-6 14-14 14H35L23 65v-9h-3c-8 0-14-6-14-14v-8c0-8 6-14 14-14Z" fill="#fff"/>
    <path d="M24 36v8M34 30v20M44 34v12M54 38v4" stroke="#4F46E5" stroke-width="5" stroke-linecap="round"/>
    <circle cx="62" cy="14" r="10" fill="${C.orange}" stroke="#fff" stroke-width="4"/>
    ${text(96, 33, "Let Agent Speak", 28, 760, word)}
    ${text(96, 61, "Your agent speaks when it’s done.", 15, 500, light ? "#D7D3E6" : C.muted)}
  </g>`;
}

function logoMark(x, y, scale = 1) {
  return `<g transform="translate(${x} ${y}) scale(${scale})">
    <rect width="76" height="76" rx="19" fill="url(#brand)"/>
    <path d="M20 20h28c8 0 14 6 14 14v8c0 8-6 14-14 14H35L23 65v-9h-3c-8 0-14-6-14-14v-8c0-8 6-14 14-14Z" fill="#fff"/>
    <path d="M24 36v8M34 30v20M44 34v12M54 38v4" stroke="#4F46E5" stroke-width="5" stroke-linecap="round"/>
    <circle cx="62" cy="14" r="10" fill="${C.orange}" stroke="#fff" stroke-width="4"/>
  </g>`;
}

function kicker(label, dark = false) {
  return `<g transform="translate(72 72)"><rect width="290" height="52" rx="26" fill="${dark ? "#3A3845" : "#17171C"}"/>${text(145, 35, label, 22, 650, C.white, "middle")}</g>`;
}

function footer(n, dark = false) {
  const c = dark ? "#CFC9DC" : C.muted;
  return `${text(72, 1372, "LET AGENT SPEAK · 开源项目", 18, 650, c)}${text(1008, 1372, `${String(n).padStart(2, "0")} / 08`, 18, 650, c, "end")}`;
}

function pill(x, y, w, label, active = false) {
  return `<g transform="translate(${x} ${y})"><rect width="${w}" height="64" rx="32" fill="${active ? "url(#brand)" : "#FFFFFF"}" stroke="${active ? "none" : C.soft}" stroke-width="2"/>${text(w / 2, 41, label, 24, 650, active ? C.white : C.ink, "middle")}</g>`;
}

const pages = [];

pages.push(`${base(C.ink)}
  <image href="${hero}" x="0" y="0" width="1080" height="1440" preserveAspectRatio="xMidYMid slice"/>
  <rect width="1080" height="1440" fill="url(#darkFade)"/>
  ${kicker("一个开发者的真实刚需", true)}
  ${text(72, 236, "我终于不用", 88, 780, C.white)}
  ${text(72, 342, "盯着 AI 干活了", 88, 780, C.white)}
  <rect x="72" y="395" width="632" height="5" rx="3" fill="${C.orange}"/>
  ${text(72, 456, "它做完，或者需要我时，", 30, 560, "#F4F0FA")}
  ${text(72, 500, "会直接开口叫我。", 30, 560, "#F4F0FA")}
  <g transform="translate(72 1118)" filter="url(#shadow)">
    <rect width="760" height="138" rx="32" fill="#FFFFFF"/>
    <circle cx="64" cy="69" r="30" fill="url(#brand)"/>
    <path d="M52 68h8l10-10v22L60 70h-8Z" fill="#fff"/><path d="M75 61c7 6 7 12 0 18" fill="none" stroke="#fff" stroke-width="4" stroke-linecap="round"/>
    ${text(116, 57, "“检查已完成，所有测试通过。”", 29, 680, C.ink)}
    ${text(116, 98, "现在，我可以放心去做别的事。", 22, 500, C.muted)}
  </g>
  ${brand(72, 1290, .72, true)}
</svg>`);

pages.push(`${base()}
  ${kicker("为什么要做它")}
  ${text(72, 205, "最累的不是等", 72, 780)}
  ${text(72, 295, "是反复回来确认", 72, 780)}
  ${text(72, 357, "Agent 在工作，我的注意力却还被它绑着。", 27, 500, C.muted)}
  <g transform="translate(72 432)">
    <rect width="936" height="720" rx="44" fill="${C.ink}"/>
    <path d="M118 116v488" stroke="#3F3D48" stroke-width="4"/>
    ${[
      [116, "10:21", "开始跑测试", "先去倒杯水"],
      [260, "10:24", "回来瞄一眼", "还在跑"],
      [404, "10:27", "又看一眼", "还是没有结果"],
      [548, "10:31", "卡在一次授权", "其实早就需要我了"],
    ].map(([y, time, a, b], i) => `<g transform="translate(0 ${y})"><circle cx="118" cy="0" r="18" fill="${i === 3 ? C.orange : C.purple}" stroke="${C.ink}" stroke-width="7"/>${text(170, -16, time, 20, 650, "#A9A4B4")}${text(170, 24, a, 32, 700, C.white)}${text(560, 24, b, 24, 500, i === 3 ? "#FDBA74" : "#A9A4B4")}</g>`).join("")}
  </g>
  <g transform="translate(104 1196)"><rect width="872" height="100" rx="28" fill="#E9E0FF"/>${text(436, 61, "我不是在等结果，我是在等一个明确的信号。", 27, 700, "#513B87", "middle")}</g>
  ${footer(2)}
</svg>`);

pages.push(`${base()}
  ${kicker("新的工作流")}
  ${text(72, 205, "现在，我可以", 72, 780)}
  ${text(72, 295, "真的离开电脑", 72, 780)}
  <image href="${hero}" x="0" y="390" width="1080" height="330" preserveAspectRatio="xMidYMid slice"/>
  <rect x="0" y="390" width="1080" height="330" fill="#11121A" fill-opacity=".15"/>
  <g transform="translate(72 665)">
    ${[
      ["01", "把任务交给 Agent", "让它继续跑测试、改代码或部署。"],
      ["02", "去做真正需要我的事", "写文档、喝水，或者干脆离开屏幕。"],
      ["03", "听见结果再回来", "做完会说，遇到阻塞也会说清楚。"],
    ].map(([n, a, b], i) => `<g transform="translate(0 ${i * 190})"><rect width="936" height="158" rx="34" fill="${i === 2 ? "url(#brand)" : C.white}" filter="url(#shadow)"/><circle cx="72" cy="79" r="34" fill="${i === 2 ? "#7166AE" : "#E9E0FF"}"/>${text(72, 89, n, 20, 760, i === 2 ? C.white : C.purple, "middle")}${text(132, 65, a, 31, 740, i === 2 ? C.white : C.ink)}${text(132, 108, b, 22, 500, i === 2 ? "#E8E2FF" : C.muted)}</g>`).join("")}
  </g>
  ${footer(3)}
</svg>`);

pages.push(`${base("#18131F")}
  ${kicker("听得见的结果", true)}
  ${text(72, 205, "做完会说", 76, 780, C.white)}
  ${text(72, 298, "卡住也会说", 76, 780, C.white)}
  ${text(72, 360, "不是泛泛提醒，而是一句话告诉我发生了什么。", 27, 500, "#B9B3C5")}
  <g transform="translate(72 450)" filter="url(#shadow)">
    <rect width="936" height="326" rx="44" fill="#FFFFFF"/>
    <circle cx="88" cy="88" r="42" fill="url(#brand)"/>
    <path d="M69 85h12l15-14v34L81 91H69Z" fill="#fff"/><path d="M101 75c12 10 12 22 0 32" fill="none" stroke="#fff" stroke-width="5" stroke-linecap="round"/>
    ${text(156, 75, "任务完成", 23, 700, C.purple)}
    ${text(64, 174, "“代码检查已经完成，", 40, 760)}
    ${text(64, 226, "所有测试通过。”", 40, 760)}
    ${text(64, 282, "我只需要知道结果，不必再回来确认。", 23, 500, C.muted)}
  </g>
  <g transform="translate(72 824)" filter="url(#shadow)">
    <rect width="936" height="326" rx="44" fill="#2A2132" stroke="#5E4B69" stroke-width="2"/>
    <circle cx="88" cy="88" r="42" fill="${C.orange}"/>
    ${text(88, 102, "!", 42, 800, C.white, "middle")}
    ${text(156, 75, "需要操作", 23, 700, "#FDBA74")}
    ${text(64, 174, "“部署等待权限确认，", 40, 760, C.white)}
    ${text(64, 226, "请回到电脑批准。”", 40, 760, C.white)}
    ${text(64, 282, "需要我时，把下一步直接说清楚。", 23, 500, "#B9B3C5")}
  </g>
  <g transform="translate(72 1210)">${pill(0, 0, 228, "完成", true)}${pill(248, 0, 270, "阻塞", false)}${pill(538, 0, 326, "需要我", false)}</g>
  ${footer(4, true)}
</svg>`);

pages.push(`${base()}
  ${kicker("怎么工作的")}
  ${text(72, 205, "不是普通弹窗", 72, 780)}
  ${text(72, 295, "是一条能听见的完成链路", 60, 780)}
  ${text(72, 355, "各组件保持独立，因此语音、消息和 Agent 都能替换。", 26, 500, C.muted)}
  <g transform="translate(72 460)">
    ${[
      [0, "01", "AI Agent", "Codex · Claude Code · OpenClaw", C.purple],
      [218, "02", "认证消息入口", "只允许已配置的 Agent 发送", C.blue],
      [436, "03", "局域网通知", "把结果可靠地送到 Mac", "#0EA5E9"],
      [654, "04", "本地语音", "Qwen3-TTS · macOS say 兜底", C.orange],
    ].map(([y, n, a, b, color], i) => `<g transform="translate(0 ${y})"><rect width="936" height="170" rx="36" fill="${C.white}" filter="url(#shadow)"/><rect width="18" height="170" rx="9" fill="${color}"/><circle cx="86" cy="85" r="38" fill="${color}20"/>${text(86, 95, n, 22, 780, color, "middle")}${text(154, 73, a, 34, 760)}${text(154, 118, b, 22, 500, C.muted)}${i < 3 ? `<path d="M468 174v38" stroke="${C.ink}" stroke-width="4" stroke-linecap="round"/><path d="m456 200 12 13 12-13" fill="none" stroke="${C.ink}" stroke-width="4" stroke-linecap="round" stroke-linejoin="round"/>` : ""}</g>`).join("")}
  </g>
  <g transform="translate(72 1280)"><rect width="936" height="70" rx="24" fill="#E9E0FF"/>${text(468, 45, "任务文本不需要交给额外的云端语音服务", 24, 700, "#513B87", "middle")}</g>
  ${footer(5)}
</svg>`);

pages.push(`${base()}
  ${kicker("我的设计底线")}
  ${text(72, 205, "提醒工具", 72, 780)}
  ${text(72, 295, "不该成为新的负担", 72, 780)}
  <g transform="translate(72 420)">
    ${[
      [0, 0, "⌂", "局域网内运行", "默认不把通知内容交给外部语音服务。", C.purple],
      [484, 0, "声", "中文本地语音", "Apple Silicon 可选 Qwen3-TTS。", C.blue],
      [0, 360, "20", "闲置自动休眠", "20 分钟无朗读后释放模型内存。", "#0EA5E9"],
      [484, 360, "↺", "失败自动兜底", "神经语音异常时回退到系统声音。", C.orange],
    ].map(([x, y, icon, a, b, color]) => `<g transform="translate(${x} ${y})"><rect width="452" height="318" rx="40" fill="${C.white}" filter="url(#shadow)"/><circle cx="72" cy="72" r="38" fill="${color}1F"/>${text(72, 83, icon, icon === "20" ? 22 : 31, 780, color, "middle")}${text(42, 158, a, 31, 760)}${text(42, 209, b.split("。")[0] + "。", 21, 500, C.muted)}${b.includes("。", b.indexOf("。") + 1) ? text(42, 244, b.split("。")[1], 21, 500, C.muted) : ""}</g>`).join("")}
  </g>
  <g transform="translate(72 1168)"><rect width="936" height="126" rx="32" fill="${C.ink}"/>${text(44, 51, "当前朗读端运行在 macOS", 27, 700, C.white)}${text(44, 91, "其他机器上的 Agent 可通过可信局域网接入。", 22, 500, "#C7C2CF")}</g>
  ${footer(6)}
</svg>`);

pages.push(`${base("#141419")}
  ${kicker("目前已经支持", true)}
  ${text(72, 205, "一个入口", 76, 780, C.white)}
  ${text(72, 298, "接住不同 Agent", 76, 780, C.white)}
  ${text(72, 360, "服务端不需要知道是谁在使用它。", 28, 500, "#B9B3C5")}
  <g transform="translate(72 450)">
    ${[
      [0, 0, "C", "Codex"], [484, 0, "CC", "Claude Code"],
      [0, 224, "OC", "OpenClaw"], [484, 224, "M", "其他 MCP 客户端"],
    ].map(([x, y, icon, label], i) => `<g transform="translate(${x} ${y})"><rect width="452" height="190" rx="36" fill="${i === 0 ? "url(#brand)" : "#24242C"}" stroke="${i === 0 ? "none" : "#3A3944"}" stroke-width="2"/><circle cx="72" cy="74" r="38" fill="#3D3B49"/>${text(72, 83, icon, icon.length > 1 ? 18 : 28, 780, C.white, "middle")}${text(40, 151, label, label.length > 12 ? 24 : 31, 720, C.white)}</g>`).join("")}
  </g>
  <g transform="translate(72 990)">
    <rect width="936" height="235" rx="44" fill="#F7F3EC"/>
    ${text(48, 68, "MIT 开源", 24, 760, C.purple)}
    ${text(48, 126, "Let Agent Speak", 48, 800, C.ink)}
    ${text(48, 176, "你的 Agent 做完时，会自己告诉你。", 25, 560, C.muted)}
    ${logoMark(812, 68, 1.05)}
  </g>
  ${footer(7, true)}
</svg>`);

pages.push(`${base(C.ink)}
  <image href="${hero}" x="0" y="0" width="1080" height="1440" preserveAspectRatio="xMidYMid slice"/>
  <rect width="1080" height="1440" fill="#101016" fill-opacity=".66"/>
  ${brand(72, 72, .78, true)}
  ${text(72, 252, "我把它开源了", 78, 800, C.white)}
  ${text(72, 336, "Let Agent Speak", 58, 760, "#C4B5FD")}
  ${text(72, 397, "它没有让 AI 更聪明，", 28, 520, "#E9E5EF")}
  ${text(72, 440, "只是把我的注意力还给了我。", 28, 520, "#E9E5EF")}
  <g transform="translate(72 550)" filter="url(#shadow)">
    <rect width="936" height="556" rx="44" fill="#F8F6F1"/>
    ${text(52, 72, "你希望 Agent 在什么时候叫你？", 34, 760, C.ink)}
    ${[
      [130, "A", "任务做完就说"],
      [250, "B", "只有卡住时说"],
      [370, "C", "两种都要"],
    ].map(([y, n, label], i) => `<g transform="translate(52 ${y})"><rect width="832" height="90" rx="26" fill="${i === 2 ? "url(#brand)" : C.white}" stroke="${i === 2 ? "none" : C.soft}" stroke-width="2"/><circle cx="48" cy="45" r="26" fill="${i === 2 ? "#3D3B49" : "#E9E0FF"}"/>${text(48, 54, n, 20, 760, i === 2 ? C.white : C.purple, "middle")}${text(94, 57, label, 28, 700, i === 2 ? C.white : C.ink)}</g>`).join("")}
    ${text(52, 520, "评论区告诉我｜下一篇拆安装和踩坑", 23, 650, C.muted)}
  </g>
  <g transform="translate(72 1170)"><rect width="570" height="92" rx="46" fill="${C.orange}"/>${text(285, 58, "GitHub 搜：Let Agent Speak", 26, 760, C.white, "middle")}</g>
  ${footer(8, true)}
</svg>`);

for (let i = 0; i < pages.length; i += 1) {
  const n = String(i + 1).padStart(2, "0");
  const svg = join(dir, `${n}.svg`);
  const png = join(dir, `${n}.png`);
  writeFileSync(svg, pages[i]);
  execFileSync("/usr/bin/sips", ["-s", "format", "png", svg, "--out", png], { stdio: "ignore" });
}

console.log(`Generated ${pages.length} cards in ${dir}`);
