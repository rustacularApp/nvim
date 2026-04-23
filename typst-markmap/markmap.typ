#import "@preview/cetz:0.5.0"

#let default-cfg = (
  dx: 5.2em,
  leaf-step: 1.55em,
  sibling-gap: 0.35em,
  text-gap: 0.55em,
  dot: 0.10em,
  curve: 1.5em,
  font-size: 8pt,
  edge-stroke: rgb("#999"),
)

// --- The Magic Helper: Rectified ---
#let transform-input(it) = {
  if type(it) == dictionary {
    let pairs = it.pairs()
    if pairs.len() == 0 { return none }
    // Take the first key as the label, and its value as the children
    let (label, val) = pairs.at(0)

    let children = ()
    if type(val) == dictionary {
      // Handle "Key": ("SubKey": "Value")
      children = val.pairs().map(p => transform-input(( (p.at(0)): p.at(1) )))
    } else if type(val) == array {
      // Handle "Key": ("A", "B", ("C": "D"))
      children = val.map(child => transform-input(child))
    } else if val != none {
      // Handle "Key": "LeafValue"
      children = ( (label: val, children: ()), )
    }

    (label: label, children: children)
  } else {
    // Base case: it's just a string or content block
    (label: it, children: ())
  }
}

#let render-markmap(data, config-overrides: (:)) = context {
  let cfg = default-cfg
  for (k, v) in config-overrides {
    cfg.insert(k, v)
  }

  let root = transform-input(data)
  if root == none { return }

  set text(size: cfg.font-size)
  let abs-len(l) = measure(h(l)).width

  let dx = abs-len(cfg.dx)
  let leaf-step = abs-len(cfg.leaf-step)
  let sibling-gap = abs-len(cfg.sibling-gap)
  let text-gap = abs-len(cfg.text-gap)
  let dot = abs-len(cfg.dot)
  let curve = abs-len(cfg.curve)
  let padding = abs-len(0.2em)
  let branch-pad = abs-len(1.5em)
  let y-offset = abs-len(0.15em)

  let layout-node(node, depth: 0, x0: 0pt, y0: 0pt) = {
    let m = measure([#node.label])
    let text-width = m.width
    let line-end-x = x0 + text-gap + text-width + padding
    let next-x0 = calc.max(x0 + dx, line-end-x + branch-pad)

    if node.children.len() == 0 {
      (node: (label: node.label, x: x0, y: y0, line-end-x: line-end-x, children: ()), next-y: y0 + leaf-step)
    } else {
      let kids = ()
      let current-y = y0
      for child in node.children {
        let res = layout-node(child, depth: depth + 1, x0: next-x0, y0: current-y)
        kids = kids + (res.node,)
        current-y = res.next-y + sibling-gap
      }
      let next-y = current-y - sibling-gap
      let my-y = (kids.first().y + kids.last().y) / 2.0
      (node: (label: node.label, x: x0, y: my-y, line-end-x: line-end-x, children: kids), next-y: next-y)
    }
  }

  let laid = layout-node(root)

  cetz.canvas({
    import cetz.draw: *
    let draw-tree(n) = {
      let x = n.x
      let y = -n.y
      let lx = n.line-end-x
      for child in n.children {
        let cx = child.x
        let cy = -child.y
        let bend = if (cx - lx) > (2.0 * curve) { curve } else { (cx - lx) / 2.0 }
        bezier((lx, y), (cx - dot, cy), (lx + bend, y), (cx - bend, cy), stroke: (paint: cfg.edge-stroke, thickness: 1pt))
        draw-tree(child)
      }
      line((x, y), (lx, y), stroke: (paint: cfg.edge-stroke, thickness: 1pt))
      circle((x, y), radius: 2pt, fill: rgb("#1f77b4"), stroke: none)
      content((x + text-gap, y + y-offset), [#n.label], anchor: "south-west")
    }
    draw-tree(laid.node)
  })
}

// --- Usage Guide ---
// 1. Root MUST be a dictionary: ("Root": children)
// 2. Keys MUST be strings: "Title": ...
// 3. Values can be: Strings, Arrays, or further Dictionaries.
