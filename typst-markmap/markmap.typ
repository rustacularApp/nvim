#import "@preview/cetz:0.5.0"

#let default-cfg = (
  dx: 5.2em,
  leaf-step: 1.55em,
  sibling-gap: 0.35em,
  text-gap: 0.55em,
  dot: 0.10em,
  curve: 1.5em,
  font-size: 8pt,
  bg-color: black,
  text-color: white,
  root-dot-color: rgb("#1f77b4"),
  branch-colors: (
    rgb("#ff7f0e"), // Orange
    rgb("#2ca02c"), // Green
    rgb("#d62728"), // Red
    rgb("#9467bd"), // Purple
    rgb("#17becf"), // Cyan
  ),
)

#let transform-input(it) = {
  if type(it) == dictionary {
    let pairs = it.pairs()
    if pairs.len() == 0 { return none }
    let (label, val) = pairs.at(0)
    let children = ()
    if type(val) == dictionary {
      children = val.pairs().map(p => transform-input(( (p.at(0)): p.at(1) )))
    } else if type(val) == array {
      children = val.map(child => transform-input(child))
    } else if val != none {
      children = ( (label: val, children: ()), )
    }
    (label: label, children: children)
  } else {
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

  // Set local text color
  set text(size: cfg.font-size, fill: cfg.text-color)
  
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

  // Wrap in a block for background
  block(fill: cfg.bg-color, inset: 1em, radius: 4pt, {
    cetz.canvas({
      import cetz.draw: *
      
      let draw-tree(n, current-color, is-root: false) = {
        let x = n.x
        let y = -n.y
        let lx = n.line-end-x
        
        for (i, child) in n.children.enumerate() {
          let cx = child.x
          let cy = -child.y
          
          // Logic: If we are at the root, pick a new color for each child.
          // Otherwise, inherit the branch color.
          let branch-c = if is-root {
            cfg.branch-colors.at(calc.rem(i, cfg.branch-colors.len()))
          } else {
            current-color
          }
          
          let bend = if (cx - lx) > (2.0 * curve) { curve } else { (cx - lx) / 2.0 }
          
          // Draw connecting line to child
          bezier((lx, y), (cx - dot, cy), (lx + bend, y), (cx - bend, cy), 
                 stroke: (paint: branch-c, thickness: 1pt))
          
          draw-tree(child, branch-c)
        }
        
        // Underline for current node
        line((x, y), (lx, y), stroke: (paint: if is-root { cfg.text-color } else { current-color }, thickness: 1pt))
        
        // Node Dot
        if is-root {
          circle((x, y), radius: 2.5pt, fill: cfg.root-dot-color, stroke: none)
        } else {
          circle((x, y), radius: 1.5pt, fill: current-color, stroke: none)
        }
        
        content((x + text-gap, y + y-offset), [#n.label], anchor: "south-west")
      }
      
      // Start recursion with text-color as fallback for root
      draw-tree(laid.node, cfg.text-color, is-root: true)
    })
  })
}

#render-markmap(
  (
    "Backend Tech": (
      "Language": "Rust",
      "Stack": ("Axum", "Tokio", "Sea-ORM"),
      "Deeply": (
        "Nested": (
          "Nodes": "Done!"
        )
      ),
      "Auth": ("JWT", "OAuth2", "Argon2")
    )
  )
)
