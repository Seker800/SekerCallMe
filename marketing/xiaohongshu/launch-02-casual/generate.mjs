import { execFileSync } from "node:child_process";
import { writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const dir = dirname(fileURLToPath(import.meta.url));
const W = 1080;
const H = 1440;
const ink = "#242329";
const paper = "#F7F4ED";
const purple = "#705CF6";
const palePurple = "#E9E3FF";
const orange = "#FF7849";
const gray = "#77737E";
const line = "#D8D1C6";

const defs = `<defs>
  <pattern id="dots" width="42" height="42" patternUnits="userSpaceOnUse"><circle cx="3" cy="3" r="2" fill="#D8D1C6" opacity=".42"/></pattern>
  <filter id="smallShadow" x="-10%" y="-10%" width="120%" height="130%"><feDropShadow dx="0" dy="8" stdDeviation="12" flood-color="#413B32" flood-opacity=".10"/></filter>
</defs>`;

function start(bg = paper, dotted = true) {
  return `<svg xmlns="http://www.w3.org/2000/svg" width="${W}" height="${H}" viewBox="0 0 ${W} ${H}">${defs}<rect width="1080" height="1440" fill="${bg}"/>${dotted ? '<rect width="1080" height="1440" fill="url(#dots)"/>' : ""}`;
}

function t(x, y, value, size, weight = 600, color = ink, anchor = "start", family = "PingFang SC, Hiragino Sans GB, sans-serif") {
  return `<text x="${x}" y="${y}" font-family="${family}" font-size="${size}" font-weight="${weight}" fill="${color}" text-anchor="${anchor}">${value}</text>`;
}

function note(x, y, value, width = 310, color = ink, bg = "#FFF") {
  return `<g transform="translate(${x} ${y}) rotate(-1)"><rect width="${width}" height="62" rx="18" fill="${bg}" stroke="${color}" stroke-width="3"/>${t(width / 2, 41, value, 22, 650, color, "middle")}</g>`;
}

function underline(x, y, width, color = orange) {
  return `<path d="M${x} ${y} q${width * .25} 10 ${width * .5} 1 t${width * .5} 3" fill="none" stroke="${color}" stroke-width="9" stroke-linecap="round"/>`;
}

function mac(x, y, scale = 1) {
  return `<g transform="translate(${x} ${y}) scale(${scale})">
    <rect x="0" y="0" width="520" height="320" rx="28" fill="#2D2C33"/>
    <rect x="22" y="22" width="476" height="276" rx="14" fill="#19191E"/>
    <circle cx="260" cy="11" r="4" fill="#77737E"/>
    <path d="M-35 320h590l-38 46H3Z" fill="#B9B6B1"/>
    <path d="M215 320h90l-10 17h-70Z" fill="#8C8884"/>
    <path d="M82 92h150M82 132h270M82 172h210M82 212h305" stroke="#7060F6" stroke-width="14" stroke-linecap="round" opacity=".8"/>
    <path d="M420 104q42 30 0 60M448 82q72 55 0 107" fill="none" stroke="${orange}" stroke-width="12" stroke-linecap="round"/>
  </g>`;
}

const pages = [];

pages.push(`${start()}
  ${note(72, 72, "随手做了个小东西", 300, ink, "#FFFFFF")}
  ${t(72, 260, "AI 干完活", 94, 780)}
  ${t(72, 374, "会喊我一声了", 94, 780)}
  ${underline(72, 408, 540)}
  ${t(76, 486, "不用再隔几分钟回去瞄一眼", 31, 500, gray)}
  <g transform="translate(486 502) rotate(4)"><rect width="408" height="126" rx="28" fill="#FFFFFF" stroke="${ink}" stroke-width="4"/>${t(204, 52, "“测试过了，", 27, 650, ink, "middle")}${t(204, 91, "任务完成。”", 27, 650, ink, "middle")}<path d="M36 126l-28 34 66-34" fill="#fff" stroke="${ink}" stroke-width="4" stroke-linejoin="round"/></g>
  ${mac(115, 720, 1.55)}
  ${t(72, 1362, "Let Agent Speak", 24, 650, gray)}
</svg>`);

pages.push(`${start()}
  ${t(72, 160, "以前 vs 现在", 74, 760)}
  ${underline(72, 192, 348, purple)}
  <g transform="translate(72 280) rotate(-1)">
    <rect width="936" height="420" rx="38" fill="#FFF7E9" stroke="${orange}" stroke-width="4" filter="url(#smallShadow)"/>
    ${t(46, 74, "以前", 34, 760, orange)}
    ${t(46, 142, "开始跑任务", 30, 650)}
    ${t(46, 198, "去倒杯水", 30, 650)}
    ${t(46, 254, "回来瞄一眼", 30, 650)}
    ${t(46, 310, "再瞄一眼……", 30, 650)}
    <path d="M520 116q120 70 15 172q-92 88-8 92" fill="none" stroke="${orange}" stroke-width="9" stroke-linecap="round" stroke-dasharray="14 18"/>
    ${t(710, 183, "人走了", 28, 650, gray, "middle")}
    ${t(710, 228, "注意力没走", 38, 760, ink, "middle")}
  </g>
  <g transform="translate(72 770) rotate(1)">
    <rect width="936" height="420" rx="38" fill="${palePurple}" stroke="${purple}" stroke-width="4" filter="url(#smallShadow)"/>
    ${t(46, 74, "现在", 34, 760, purple)}
    ${t(46, 156, "任务丢给 Agent", 34, 650)}
    ${t(46, 220, "我去干别的", 34, 650)}
    <rect x="430" y="102" width="430" height="150" rx="28" fill="#FFFFFF" stroke="${ink}" stroke-width="3"/>
    ${t(645, 164, "“已经做完了。”", 31, 700, ink, "middle")}
    ${t(645, 210, "听见再回来", 26, 500, gray, "middle")}
    ${t(46, 344, "就这么点区别，但舒服很多。", 30, 650, purple)}
  </g>
</svg>`);

pages.push(`${start("#EEE9DD")}
  ${note(72, 72, "安装也没那么复杂", 330, ink, "#FFFFFF")}
  ${t(72, 230, "把仓库地址", 74, 760)}
  ${t(72, 320, "丢给你自己的 Agent", 74, 760)}
  <g transform="translate(72 405)">
    <rect width="936" height="710" rx="42" fill="#FFFFFF" filter="url(#smallShadow)"/>
    ${t(48, 60, "你", 22, 650, gray)}
    <g transform="translate(48 90)"><rect width="780" height="116" rx="28" fill="${palePurple}"/>${t(32, 48, "github.com/Seker800/LetAgentSpeak", 25, 650, purple)}${t(32, 86, "帮我按仓库说明装好，装完测试一下。", 25, 650)}</g>
    ${t(48, 274, "你的 Agent", 22, 650, gray)}
    <g transform="translate(48 304)"><rect width="650" height="108" rx="28" fill="#F0F0F2"/>${t(32, 67, "好，我来检查环境并安装。", 27, 600)}</g>
    <path d="M458 458q0 72-110 72" fill="none" stroke="${orange}" stroke-width="8" stroke-linecap="round"/>
    <path d="m360 515-18 16 24 5" fill="none" stroke="${orange}" stroke-width="8" stroke-linecap="round" stroke-linejoin="round"/>
    ${t(48, 610, "然后让它自己折腾就行。", 36, 760)}
    ${t(48, 661, "不用照着教程一项项手配。", 25, 500, gray)}
  </g>
  ${t(72, 1230, "一句话版本：", 28, 700, orange)}
  ${t(72, 1280, "把地址发给 Agent，让它帮你弄好。", 34, 700)}
</svg>`);

pages.push(`${start()}
  ${t(72, 175, "它就干两件事", 78, 760)}
  ${underline(72, 207, 460, orange)}
  <g transform="translate(72 320) rotate(-1)">
    <rect width="936" height="360" rx="44" fill="#FFFFFF" stroke="${purple}" stroke-width="4" filter="url(#smallShadow)"/>
    <circle cx="100" cy="100" r="48" fill="${palePurple}"/>
    ${t(100, 116, "✓", 46, 800, purple, "middle")}
    ${t(174, 91, "干完了", 39, 760)}
    ${t(174, 145, "把结果说一声", 32, 600, gray)}
    <rect x="90" y="218" width="730" height="92" rx="25" fill="${palePurple}"/>
    ${t(455, 275, "“检查完成，没发现问题。”", 29, 650, ink, "middle")}
  </g>
  <g transform="translate(72 760) rotate(1)">
    <rect width="936" height="360" rx="44" fill="#FFFFFF" stroke="${orange}" stroke-width="4" filter="url(#smallShadow)"/>
    <circle cx="100" cy="100" r="48" fill="#FFF0E9"/>
    ${t(100, 116, "!", 46, 800, orange, "middle")}
    ${t(174, 91, "卡住了", 39, 760)}
    ${t(174, 145, "告诉我现在要做什么", 32, 600, gray)}
    <rect x="90" y="218" width="730" height="92" rx="25" fill="#FFF0E9"/>
    ${t(455, 275, "“需要你确认一下权限。”", 29, 650, ink, "middle")}
  </g>
  ${t(540, 1282, "没了，就这么简单。", 34, 680, gray, "middle", "Kaiti SC, STKaiti, PingFang SC, sans-serif")}
</svg>`);

pages.push(`${start("#F2EEE4")}
  ${note(72, 72, "自己用着方便", 264, ink, "#FFFFFF")}
  ${t(72, 240, "所以顺手", 78, 760)}
  ${t(72, 336, "开源出来了", 92, 780)}
  ${underline(72, 372, 448, purple)}
  <g transform="translate(72 470) rotate(-1)">
    <rect width="936" height="320" rx="42" fill="#FFFFFF" stroke="${ink}" stroke-width="4" filter="url(#smallShadow)"/>
    ${t(48, 82, "GitHub", 24, 650, gray)}
    ${t(48, 150, "Seker800 / LetAgentSpeak", 41, 760)}
    ${t(48, 210, "或者直接搜：Let Agent Speak", 27, 550, gray)}
    <rect x="48" y="244" width="180" height="44" rx="22" fill="${palePurple}"/>${t(138, 274, "MIT 开源", 20, 700, purple, "middle")}
  </g>
  <g transform="translate(72 870)">
    <path d="M0 0h936" stroke="${line}" stroke-width="4" stroke-linecap="round"/>
    ${t(0, 86, "我现在主要拿 Mac + Codex 用。", 34, 650)}
    ${t(0, 150, "Claude Code、OpenClaw 这些也能接。", 30, 520, gray)}
    ${t(0, 245, "想试的话，把地址丢给你的 Agent 就行。", 34, 700, purple)}
  </g>
  <g transform="translate(72 1250)"><rect width="430" height="86" rx="28" fill="${ink}"/>${t(215, 55, "拿去用吧，就这样。", 27, 650, "#FFFFFF", "middle")}</g>
</svg>`);

for (let i = 0; i < pages.length; i += 1) {
  const n = String(i + 1).padStart(2, "0");
  const svg = join(dir, `${n}.svg`);
  const png = join(dir, `${n}.png`);
  writeFileSync(svg, pages[i]);
  execFileSync("/usr/bin/sips", ["-s", "format", "png", svg, "--out", png], { stdio: "ignore" });
}

console.log(`Generated ${pages.length} casual cards in ${dir}`);
