import { Util } from "/js/util.js"

var Action = {
  log: null,
  processing: false,
  end_processing: function() {
    Action.processing = false
    document.activeElement.blur()
  },
  do_logout: function(delayed) {
    /* This is normally executed within a callback to Action.clear, which already
     * handles the Action.processing flag. If this needs to delay because of the
     * roll log updater, this context will be lost and it will need to do its
     * own Action.processing flag handling.
     */
    if(Action.log.processing === true || (delayed && Action.processing === true)) {
      window.setTimeout(Action.do_logout, 100, true); /* this checks the flag every 100 milliseconds*/
    } else {
      if(delayed) { Action.processing = true }
      Util.login.last_request = null
      Action.log.do_logout()
      if(delayed) { Action.processing = false }
      Util.login.end_processing()
    }
  },
  do_clear: function(d) {
    var fields = ['av','ov','ov_cs','ev','rv','rv_cs']
    Util.data = d
    fields.forEach((id) => { document.getElementById(id).value = '' })
  },
  handle_two: function(d) {
    Util.data = d
    if(d.success == false && d.total == 2) {
      Util.data.target = d.target || ''
      Util.data.cs = ''
    }
  },
  roll: function(e) {
    if(!Action.processing) {
      Action.processing = true
      var reroll = (e.target.id == 'reroll')
      var params = Util.get_action_fields()
      if(reroll) {
        params.reroll = true
      }

      Util.do_get_request('/action_roll', {}, params, Action.handle_two, Action.end_processing)
    }
  },
  result: function(e) {
    if(!Action.processing) {
      Action.processing = true
      var params = Util.get_action_fields()
      params.result = true

      Util.do_get_request('/action_roll', {}, params, Util.set_data, Action.end_processing)
    }
  },
  resolve: function(e) {
    if(!Action.processing) {
      Action.processing = true
      var params = Util.get_effect_fields()

      Util.do_get_request('/effect_resolve', {}, params, Util.set_data, Action.end_processing)
    }
  },
  clear: function(e, final_cb) {
    if(!Action.processing) {
      Action.processing = true
      var params = { clear: true }

      Util.do_get_request('/action_roll', {}, params, Action.do_clear, function() {
        Action.end_processing()
        if(final_cb) { final_cb() }
      })
    }
  }
}


var ActionClearButton = {
  oncreate: Util.center_line_height,
  onupdate: Util.center_line_height,
  view: function(vnode) {
    return m("span.centered", m("a.pure-button", { onclick: Action.clear }, "Clear"))
  }
}

var ActionRollButtons = {
  oncreate: Util.center_line_height,
  onupdate: Util.center_line_height,
  view: function(vnode) {
    return m("span.centered",
      Util.show_roll()    ? m("a.pure-button", { id: 'roll',   onclick: Action.roll }, "Roll")   : "",
      Util.show_reroll()  ? m("a.pure-button", { id: 'reroll', onclick: Action.roll }, "Reroll") : "",
      Util.show_break()   ? m("br") : "",
      Util.show_submit()  ? m("a.pure-button", { onclick: Action.result }, "Submit")   : "",
      Util.show_resolve() ? m("a.pure-button", { onclick: Action.resolve }, "Resolve") : "")
  }
}

var ActionDataView = {
  view: function(vnode) {
    var data = Util.data
    return Object.keys(data).length === 0 ? [] : [
      m(".pure-u-1-3.centered", "Total: "+data.total, m("br"), "Dice: "+data.last_roll.join(', ')),
      m(".pure-u-1-3.centered", "Target: "+data.target),
      m(".pure-u-1-3.centered", "CS: "+data.cs),
    ]
  }
}

var ActionResolvedView = {
  view: function(vnode) {
    return m(".pure-u-5-5", { style: Util.data.resolved ? "text-align: center; color: white; background-color: green" :
	                                                    "display: none" }, "RAPs: " + Util.data.raps)
  }
}

export { Util, Action, ActionClearButton, ActionRollButtons, ActionDataView, ActionResolvedView }
