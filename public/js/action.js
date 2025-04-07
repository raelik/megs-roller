var Util = {
  show_roll: function() {
    return !Action.login.processing && !Action.data.last_roll
  },
  show_log: function() {
    return Action.login.logged_in()
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
    var c     = document.getElementById('character')
    return Object.assign({ av: av.value, ov: ov.value, ov_cs: ov_cs.value }, c ? { c: c.value } : {})
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
  log: [],
  login: null,
  processing: false,
  set_data: (d) => { Action.data = d },
  set_log: (l) => { Action.log = l },
  has_data: function() {
    return Object.keys(Action.data).length !== 0
  },
  do_clear: function(d) {
    var fields = ['av','ov','ov_cs','ev','rv','rv_cs']
    Action.data = d
    fields.forEach((id) => { document.getElementById(id).value = '' })
  },
  handle_two: function(d) {
    Action.data = d
    if(d.success == false && d.total == 2) {
      Action.data.target = d.target || ''
      Action.data.cs = ''
    }
    Action.processing = false
  },
  do_get_request: function(url, params, cb, final_cb) {
    var root = document.body
    root.style.cursor = "wait"

    Promise.all([
      m.request({
        method: "GET",
        url: url,
        headers: (Action.login.logged_in() ? { 'X-MEGS-Session-Signature': Action.login.sign() } : {}),
        params: params
      })
      .then(function(d) {
        if(cb) { cb(d) }
      })
    ])
    .catch(err => null)
    .finally(function() {
      if(final_cb) { final_cb() }
      root.style.cursor = "auto"
    })
  },
  roll: function(e) {
    if(!Action.processing) {
      Action.processing = true
      var reroll = (e.target.id == 'reroll')
      var params = Util.get_action_fields()
      if(reroll) {
        params.reroll = true
      }

      Action.do_get_request('/action_roll', params, Action.handle_two, () => { Action.processing = false })
    }
  },
  roll_log: function(cb) {
    if(Action.login.logged_in()) {
      Action.do_get_request('/roll_log', {}, Action.set_log, cb)
    }
  },
  result: function(e) {
    if(!Action.processing) {
      Action.processing = true
      var params = Util.get_action_fields()
      params.result = true

      Action.do_get_request('/action_roll', params, Action.set_data, () => { Action.processing = false })
    }
  },
  resolve: function(e) {
    if(!Action.processing) {
      Action.processing = true
      var params = Util.get_effect_fields()

      Action.do_get_request('/effect_resolve', params, Action.set_data, () => { Action.processing = false })
    }
  },
  clear: function(e, final_cb) {
    if(!Action.processing) {
      Action.processing = true
      var params = { clear: true }

      Action.do_get_request('/action_roll', params, Action.do_clear, function() {
        Action.processing = false
        if(final_cb) { final_cb() }
      })
    }
  },
  log_promise: function() {
    new Promise(r => setTimeout(r, 5000)).then(function() {
      Action.roll_log(function() {
        if(Action.login.logged_in()) {
          Action.log_promise();
        }
      })
    })
  },
  start_log: function(vnode) {
    Action.roll_log(function() {
      if(Action.login.logged_in()) {
        Action.log_promise();
      }
    })
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

var ActionLogRow = {
  view: function(e) {
    var roll = e.attrs.roll
    // ----- UL/LI version
    // var trailer = roll.success ? [('CS: ' + roll.cs), (roll.ev + '/' + roll.rv + (roll.rv_cs ? (' (' + roll.rv_cs + ')') : '')),
    //                              ('RAPs: ' + roll.raps)] : []
    // return m("li", [roll.user, roll.character, (roll.av + '/' + roll.ov + (roll.ov_cs ? (' (' + roll.ov_cs + ')') : '')),
    //                (roll.total + " vs. " + roll.target + ' (' + (roll.success ? 'SUCCESS' : 'FAIL') + ')')].concat(trailer).join(' - '))
    // ☑ &#x2611; ☒ &#x2612;
    // ----- Table Version
    // return m("tr", m("td", roll.user), m("td", roll.character), m("td.centered", roll.av + '/' + roll.ov + (roll.ov_cs ? (' (' + roll.ov_cs + ')') : '')),
    //               m("td.centered", roll.total + " vs. " + roll.target), m("td.centered", roll.success ? m("span.success", "☑") : m("span.failure", "☒")),
    //               m("td.centered", roll.cs), m("td.centered", roll.ev ? (roll.ev + '/' + roll.rv + (roll.rv_cs ? (' (' + roll.rv_cs + ')') : '')) : ''),
    //               m("td.centered", roll.raps))
    var pre_fields  = [roll.character ? (roll.character + ' (' + roll.user + ')') : roll.user,
                       'A/O: ' + roll.av + '/' + roll.ov + (roll.ov_cs ? (' (' + roll.ov_cs + ')') : ''),
                       roll.total + " v " + roll.target].join(', ')
    var post_fields = roll.success ? ', ' +
      ['CS: ' + roll.cs, 'E/R: ' + roll.ev + '/' + roll.rv + (roll.rv_cs ? (' (' + roll.rv_cs + ')') : ''), 'RAPs: ' + roll.raps].join(', ') : ''
    var mark_cl     = roll.success ? "success" : "failure"
    var mark        = roll.success ? " ☑" : " ☒"

    return m("span", pre_fields, m("span."+mark_cl, mark), post_fields, m("br"))
  }
}

var ActionRollLog = {
  oninit: Action.start_log,
  view: function(e) {
    // ----- Table Version
    // var headers = "Player|Character|AV/OV|Roll|W/L|CS|EV/RV|RAPs".split('|')
    // return [m(".pure-u-5-5", m("table.pure-u.pure-table#roll_log", m("thead", m("tr", headers.map(h => m("th", h)))),
    //                          m("tbody", Action.log.map((r, i) => m(ActionLogRow, { key: 'log_'+i, roll: r })))))]
    return [m(".pure-u-5-5#roll_log", Action.log.map((r, i) => m(ActionLogRow, { key: 'log_'+i, roll: r })))]
  }
}
export { Util, Action, ActionClearButton, ActionRollButtons, ActionDataView, ActionResolvedView, ActionRollLog }
