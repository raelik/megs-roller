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
  log_data: {},
  login: null,
  log_processing: false,
  processing: false,
  last_request: null,
  end_processing: function() {
    Action.processing = false
    document.activeElement.blur()
  },
  modal: null,
  log_detail: null,
  selected_row: null,
  log_interval: null,
  set_data: (d) => { Action.data = d },
  set_log: function(l) {
    Action.log = l.map(r => r.hash_key)
    l.forEach((r) => { Action.log_data[r.hash_key] = r })
    Action.log_processing = false
  },
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
      if(url != '/roll_log') { Action.last_request = Date.now() }
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

      Action.do_get_request('/action_roll', params, Action.handle_two, Action.end_processing)
    }
  },
  get_roll_log: function(cb) {
    if(Action.login.logged_in()) {
      Action.log_processing = true
      Action.do_get_request('/roll_log', {}, Action.set_log, cb)
    } else if(Action.log_interval) {
      clearInterval(Action.log_interval)
    }
  },
  result: function(e) {
    if(!Action.processing) {
      Action.processing = true
      var params = Util.get_action_fields()
      params.result = true

      Action.do_get_request('/action_roll', params, Action.set_data, Action.end_processing)
    }
  },
  resolve: function(e) {
    if(!Action.processing) {
      Action.processing = true
      var params = Util.get_effect_fields()

      Action.do_get_request('/effect_resolve', params, Action.set_data, Action.end_processing)
    }
  },
  clear: function(e, final_cb) {
    if(!Action.processing) {
      Action.processing = true
      var params = { clear: true }

      Action.do_get_request('/action_roll', params, Action.do_clear, function() {
        Action.end_processing()
        if(final_cb) { final_cb() }
      })
    }
  },
  setup_log_detail: function(vnode) {
    Action.modal      = document.getElementById('modal')
    Action.log_detail = document.getElementById('log_detail')
    Action.log_close  = document.getElementById('log_close')
    Action.modal.style.height = document.getElementById('roll_log').offsetTop + 'px'
  },
  setup_log_row: function(vnode) {
    vnode.dom.removeEventListener('log_click', Action.show_log_detail)
    vnode.dom.addEventListener('log_click', Action.show_log_detail)
  },
  start_log: function(vnode) {
    Action.get_roll_log(function() {
      if(Action.login.logged_in()) {
        Action.log_interval = setInterval(Action.get_roll_log, 5000);
      }
    })
  },
  show_log_detail: function(e) {
    if(Action.log_processing === true) {
       window.setTimeout(Action.show_log_detail, 100, e); /* this checks the flag every 100 milliseconds*/
    } else {
      if(Action.selected_row) { document.getElementById(Action.selected_row).classList.remove('selected') }
      Action.selected_row = e.target.id
      e.target.classList.add('selected')

      var roll_log = document.getElementById('roll_log')
      log_detail.style.width  = (roll_log.offsetWidth - 25) + 'px'
      log_detail.style.height = (roll_log.offsetTop - 25) + 'px'
      modal.style.display = 'block'
      document.activeElement.blur()
    }
  },
  close_log_detail: function(e) {
    if(e.target == modal || e.target == log_close) {
      document.getElementById(Action.selected_row).classList.remove('selected')
      modal.style.display = 'none'
      Action.selected_row = null
    }
  }
}


var ActionClearButton = {
  oncreate: Util.center_line_height,
  onupdate: Util.center_line_height,
  view: function(vnode) {
    return [ m("span.centered", m("a.pure-button", { onclick: Action.clear }, "Clear")) ]
  }
}

var ActionRollButtons = {
  oncreate: Util.center_line_height,
  onupdate: Util.center_line_height,
  view: function(vnode) {
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
  view: function(vnode) {
    var data = Action.data
    return Object.keys(data).length === 0 ? [] : [
      m(".pure-u-1-3.centered", "Total: "+data.total, m("br"), "Dice: "+data.last_roll.join(', ')),
      m(".pure-u-1-3.centered", "Target: "+data.target),
      m(".pure-u-1-3.centered", "CS: "+data.cs),
    ]
  }
}

var ActionResolvedView = {
  view: function(vnode) {
    return [ m(".pure-u-5-5", { style: Action.data.resolved ? "text-align: center; color: white; background-color: green" :
	                                                      "display: none" }, "RAPs: " + Action.data.raps) ]
  }
}

var ActionLogDetail = {
  view: function(vnode) {
    var detail_table = []
    if(Action.selected_row) {

      var r       = Action.log_data[Action.selected_row]
      var mark_cl = r.success ? "success" : "failure"
      var mark    = r.success ? "&#x2611;" : "&#x2612;"
      detail_table = [m("table",
                        m("tr", m("td.hd", "Timestamp"), m("td", { colspan: 3, width: '100%' }, r.timestamp), m("td#log_close","❌")),
                        m("tr", m("td.hd", "Character"), m("td", r.character), m("td.hd", "Owner"), m("td", { colspan: 2}, r.owner)),
                        m("tr", m("td.hd", "User"), m("td", r.user),
                                m("td.hd", "AV/OV"),
                                m("td", { colspan: 2 }, r.av + ' / ' + r.ov + (r.ov_cs ? ' (' + r.ov_cs + ')' : ''))),
                        m("tr", m("td.hd", "Target"), m("td", r.target), m("td.hd", "Total"), m("td", { colspan: 2}, r.total)),
                        m("tr", m("td.hd", "Success"), m("td."+mark_cl, m.trust(mark)), m("td.hd", "Rolls"),
                                m("td", { colspan: 2 }, r.rolls.flat().join(', '))),
                        m("tr", m("td.hd", "CS"), m("td", r.cs),
                                m("td.hd", "EV/RV"),
                                m("td", { colspan: 2 },(r.ev == null ? '' : r.ev + ' / ' + r.rv) + (r.rv_cs ? ' (' + r.rv_cs + ')' : ''))),
                        m("tr", m("td.hd", "RAPs"), m("td", { colspan: 4 }, r.raps)))]
    }
    return [m("#log_detail", detail_table)]
  }
}

var ActionLogRow = {
  oncreate: Action.setup_log_row,
  view: function(vnode) {
    var key  = vnode.attrs.key
    var roll = Action.log_data[key]
    var mark_cl     = roll.success ? "success" : "failure"
    var mark        = roll.success ? " &#x2611;" : " &#x2612;"
    var post_fields = roll.success ? ', ' +
      ['CS: ' + roll.cs, 'E/R: ' + roll.ev + '/' + roll.rv + (roll.rv_cs ? (' (' + roll.rv_cs + ')') : ''), 'RAPs: ' + roll.raps].join(', ') : ''
    var pre_fields  = [roll.character ? (roll.character + ' (' + roll.user + ')') : roll.user,
                       'A/O: ' + roll.av + '/' + roll.ov + (roll.ov_cs ? (' (' + roll.ov_cs + ')') : ''),
                       roll.total + " v " + roll.target].join(', ')

    return m("span.log_row", { id: key, onclick: Action.show_log_detail }, pre_fields, m("span."+mark_cl, m.trust(mark)), post_fields, m("br"))
  }
}

var ActionRollLog = {
  oninit: Action.start_log,
  oncreate: Action.setup_log_detail,
  onupdate: function(vnode) {
    var e = document.getElementById('roll_log')
    e.style.height = (window.innerHeight - e.offsetTop) + 'px'
  },
  view: function(vnode) {
    return [m(".pure-u-5-5.centered#roll_log_header", m.trust("———————— &nbsp;Recent Rolls&nbsp; ————————")),
            m(".pure-u-5-5#roll_log", Action.log.map(r => m(ActionLogRow, { key: r }))),
            m("#modal", { onclick: Action.close_log_detail }, m(ActionLogDetail))]
  }
}
export { Util, Action, ActionClearButton, ActionRollButtons, ActionDataView, ActionResolvedView, ActionRollLog }
