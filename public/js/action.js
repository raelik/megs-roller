var Util = {
  show_roll: function() {
    return !Action.data.last_roll
  },
  show_reroll: function() {
    if(Util.show_submit() && Action.data.last_roll) {
      return Action.data.last_roll[0] == Action.data.last_roll[1]
    }
  },
  show_submit: function() {
    return Action.has_data() && Action.data.success === undefined
  },
  show_resolve: function() {
    return Util.show_effect_fields() && !Action.data.resolved
  },
  show_break: function() {
    return (Util.show_roll() || Util.show_reroll()) && (Util.show_submit() || Util.show_resolve())
  },
  show_result: function() {
    return Action.has_data() && Action.data.success !== undefined
  },
  show_effect_fields: function() {
    return Action.has_data() && Action.data.success
  },
  get_action_fields: function() {
    var av    = document.getElementById('av')
    var ov    = document.getElementById('ov')
    var ov_cs = document.getElementById('ov_cs')
    return { av: av.value, ov: ov.value, ov_cs: ov_cs.value }
  },
  get_effect_fields: function() {
    var ev    = document.getElementById('ev')
    var rv    = document.getElementById('rv')
    var rv_cs = document.getElementById('rv_cs')
    return { ev: ev.value, rv: rv.value, rv_cs: rv_cs.value }
  },
  center_line_height: function(vnode) {
    var nodes = vnode.dom.parentElement.parentElement.querySelectorAll('span')
    nodes.forEach((e) => { e.style.removeProperty('line-height') })

    var height = vnode.dom.parentElement.offsetHeight
    nodes.forEach((e) => {
      var divisor = Array.from(e.children).filter((e) => { return e.tagName == 'A' }).length
      e.style.lineHeight = (height / divisor) + "px"
    })
  }
}

var Action = {
  data: {},
  has_data: function() {
    return Object.keys(Action.data).length !== 0
  },
  do_clear: function() {
    ['av','ov','ov_cs','ev','rv','rv_cs'].forEach((id) => { document.getElementById(id).value = '' })
  },
  handle_two: function(data) {
    if(data.success == false && data.total == 2) {
      Action.data.target = data.target || ''
      Action.data.cs = ''
    }
  },
  do_get_request: function(url, params, cb) {
    var root = document.body
    root.style.cursor = "wait"

    Promise.all([
      m.request({
        method: "GET",
        url: url,
        params: params
      })
      .then(function(data) {
        Action.data = data
        if(cb) { cb(data) }
      })
    ])
    .catch(err => null)
    .finally(() => root.style.cursor = "auto")
  },
  roll: function(e) {
    var reroll = (e.target.id == 'reroll')
    var params = Util.get_action_fields()
    if(reroll) {
      params.reroll = true
    }

    Action.do_get_request('/action_roll', params, Action.handle_two)
  },
  result: function(e) {
    var params = Util.get_action_fields()
    params.result = true

    Action.do_get_request('/action_roll', params)
  },
  resolve: function(e) {
    var params = Util.get_effect_fields()

    Action.do_get_request('/effect_resolve', params)
  },
  clear: function(e) {
    var params = { clear: true }

    Action.do_get_request('/action_roll', params, Action.do_clear)
  }
}


var ActionClearButton = {
  oncreate: Util.center_line_height,
  onupdate: Util.center_line_height,
  view: function(e) {
    return [ m("span.centered", m("a.pure-button", { onclick: Action.clear }, "Clear")) ]
  }
}

var ActionRollButtons = {
  oncreate: Util.center_line_height,
  onupdate: Util.center_line_height,
  view: function(e) {
    return [ m("span.centered",
      Util.show_roll()    ? m("a.pure-button", { id: 'roll',   onclick: Action.roll }, "Roll")   : "",
      Util.show_reroll()  ? m("a.pure-button", { id: 'reroll', onclick: Action.roll }, "Reroll") : "",
      Util.show_break()   ? m("br") : "",
      Util.show_submit()  ? m("a.pure-button", { onclick: Action.result }, "Submit")   : "",
      Util.show_resolve() ? m("a.pure-button", { onclick: Action.resolve }, "Resolve") : ""
    )]
  }
}

var ActionDataView = {
  view: function(e) {
    var data = Action.data
    return Object.keys(data).length === 0 ? [] : [
      m(".pure-u-1-3.centered", "Total: "+data.total, m("br"), "Dice: "+data.last_roll.join(', ')),
      m(".pure-u-1-3.centered", "Target: "+data.target),
      m(".pure-u-1-3.centered", "CS: "+data.cs),
    ]
  }
}

var ActionResolvedView = {
  view: function(e) {
    return [ m(".pure-u-5-5", { style: Action.data.resolved ? "text-align: center; color: white; background-color: green" :
	                                                      "display: none" }, "RAPs: " + Action.data.raps) ]
  }
}
export { Util, Action, ActionClearButton, ActionRollButtons, ActionDataView, ActionResolvedView }
