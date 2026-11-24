"""Evaluate pinned upstream layouts in isolation to record a parity baseline.

The generated runner stays outside the package source and uses Node's TypeScript
transformation, not the rewritten engine. No KWin or upstream source is changed.
"""
import json
from pathlib import Path
import subprocess
import sys

upstream = Path(sys.argv[1]).resolve()
package = Path(__file__).resolve().parents[1]
scratch = package.parents[1] / ".workcache" / "upstream-layout-fixtures.ts"
files = ["util/func.ts", "util/rect.ts", "util/rectdelta.ts", "util/windrose.ts", "layouts/layoututils.ts", "layouts/layoutpart.ts", "layouts/column.ts", "layouts/tilelayout.ts", "layouts/monoclelayout.ts", "layouts/threecolumnlayout.ts", "layouts/spirallayout.ts", "layouts/quarterlayout.ts", "layouts/stackedlayout.ts", "layouts/columns.ts", "layouts/spreadlayout.ts", "layouts/floatinglayout.ts", "layouts/stairlayout.ts", "layouts/btreelayout.ts", "layouts/cascadelayout.ts"]
prefix = """
const print = () => {};
let CONFIG: any = {};
let KWINCONFIG: any = CONFIG;
const LOG = undefined;
const WindowState = { Tiled: 1, TiledAfloat: 2, Maximized: 3 };
const KWinDriver = { backendName: "kwin" };
const RectParts = { Whole: 0, Top: 1, Bottom: 2, Left: 3, Right: 4 };
"""
runner = """
const families = { tile: TileLayout, monocle: MonocleLayout, threeColumn: ThreeColumnLayout, spiral: SpiralLayout, quarter: QuarterLayout, stacked: StackedLayout, columns: ColumnsLayout, spread: SpreadLayout, floating: FloatingLayout, stair: StairLayout, binaryTree: BinaryTreeLayout, cascade: CascadeLayout };
const fixtures: any[] = [];
for (const [id, Layout] of Object.entries(families)) for (const count of [1,2,3,4,5,8]) for (const gap of [0,8]) for (const rotation of id === 'tile' || id === 'columns' ? [0,1,2,3] : [0]) {
  CONFIG = { tileLayoutInitialAngle: String(rotation), columnsLayoutInitialAngle: String(rotation), columnsBalanced: false, columnsLayerConf: [], columnsLimitColumns: false, columnsApplyConfOnNewColumns: false, spreadLayoutSpace: 4, quarterLayoutReset: false, monocleMaximize: false, stairReverse: false };
  KWINCONFIG = CONFIG;
  const windows = Array.from({length:count}, (_, i) => ({ id: String(i), weight: 1, focusTime: i, state: 0, geometry: new Rect(50,60,600,400), window: { stackingOrder: i }, isAlive: () => true }));
  const context = { backend: 'test', surfaceParams: ['DP-1','work','Desktop 1'], getPrevMaster: () => null, setPrevMaster: () => {}, getWindowById: (id:string) => windows.find(w => w.id === id) ?? null };
  const area = new Rect(13,37,1919,1049);
  const layout = new Layout();
  layout.apply(context, windows, area, gap);
  fixtures.push({ id, count, gap, rotation, area, geometries: windows.slice(0,id==='quarter'?4:count).map(w => w.geometry) });
}
console.log(JSON.stringify(fixtures,null,2));
"""
scratch.parent.mkdir(parents=True, exist_ok=True)
scratch.write_text(prefix + "\n".join((upstream / "src" / file).read_text(encoding="utf-8") for file in files) + runner, encoding="utf-8")
result = subprocess.run(["rtk", "proxy", "node", "--experimental-transform-types", str(scratch)], capture_output=True, text=True, check=True)
fixtures = json.loads(result.stdout)
target = package / "fixtures" / "layouts.json"
target.parent.mkdir(parents=True, exist_ok=True)
target.write_text(json.dumps(fixtures, indent=2) + "\n", encoding="utf-8")
print(f"Captured {len(fixtures)} cases from pinned upstream")
