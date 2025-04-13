import { Util } from "/js/action.js"
import { Log, RollLog, LogToggle, DiscordToggle } from "/js/log.js"
import { Action, ActionClearButton, ActionRollButtons,
         ActionDataView, ActionResolvedView } from "/js/action.js"
import { Login, LoginBarView } from "/js/login.js"

var Main = {
  oninit: function(vnode) {
    Login.setup()
    Action.log = Log
  },
  util: Util,     // <--------------------------
  login: Login,   // <- These are only set for
  log: Log,       // <- debug purposes.
  action: Action, // <--------------------------
  oncreate: function(vnode) {
    document.getElementById('av').focus({ focusVisible: true })
  },
  onupdate: function(vnode) {
    var viewport = document.querySelector('meta[name="viewport"]');

    if ( viewport ) {
      viewport.content = 'initial-scale=1';
      viewport.content = 'width=device-width';
    }

    if(Log.selected == null && document.activeElement.tagName != 'INPUT') {
      if(Util.show_roll()) {
        document.getElementById('av').focus()
      } else if (Util.data.success && !Util.data.resolved) {
        document.getElementById('ev').focus()
      }
    }
  },
  text_field_attrs: function(id) {
    return { id: id, type: 'text', size: 3, minlength: 1, maxlength: 3 }
  },
  effect_field_attrs: function(id) {
    var attrs = Main.text_field_attrs(id)
    return Object.assign(attrs, Util.data.resolved ? { disabled: true } : {})
  },
  action_field_attrs: function(id) {
    var attrs = Main.text_field_attrs(id)
    return Object.assign(attrs, !Util.show_roll() ? { disabled: true } : {})
  },
  result_style: function() {
    return Util.show_result() ? ("text-align: center; margin-bottom: 10px; color: white; background-color: " +
                                 (Util.data.success ? "green" : "red")) : "display: none"
  },
  result_text: function() {
    return Util.show_result() ? ("Action " + (Util.data.success ? "Succeeded!" : "FAILED.")) : ""
  },
  view: function(vnode) {
    var check = Main.check_action_field
    return m(".pure-g",
      m(".pure-u-1-4.centered", m(ActionClearButton)),
      m(".pure-u-1-2.centered", m("h2", "MEGS Roller")),
      m(".pure-u-1-4.centered.right-buttons", m(ActionRollButtons)),
      m(".pure-u-5-5",
        m(".pure-u-1-3.centered", "AV"),
        m(".pure-u-1-3.centered", "OV"),
        m(".pure-u-1-3.centered", "OV CS"),
      ),
      m(".pure-u-5-5",
        m(".pure-u-1-3.centered", m("input", Main.action_field_attrs('av'))),
        m(".pure-u-1-3.centered", m("input", Main.action_field_attrs('ov'))),
        m(".pure-u-1-3.centered", m("input", Main.action_field_attrs('ov_cs')))
      ),
      m(".pure-u-5-5", { style: "margin-bottom: 10px" }, m(ActionDataView)),
      m(".pure-u-5-5", { style: Main.result_style() }, Main.result_text()),
      m(".pure-u-5-5", { style: Util.show_effect_fields() ? "" : "display: none" },
        m(".pure-u-1-3.centered", "EV"),
        m(".pure-u-1-3.centered", "RV"),
        m(".pure-u-1-3.centered", "RV CS"),
      ),
      m(".pure-u-5-5", { style: Util.show_effect_fields() ? "" : "display: none" },
        m(".pure-u-1-3.centered", m("input", Main.effect_field_attrs('ev'))),
        m(".pure-u-1-3.centered", m("input", Main.effect_field_attrs('rv'))),
        m(".pure-u-1-3.centered", m("input", Main.effect_field_attrs('rv_cs')))
      ),
      m(ActionResolvedView),
      (Util.login.enabled ? m(LoginBarView) : ''),
      (Util.show_log() ? [m(".pure-u-5-5.centered#roll_log_header",
                            m(DiscordToggle), (Login.is_admin() ? m(LogToggle) : ''),
                            m.trust("—————— &nbsp;Recent Rolls&nbsp; ——————")),
                          m(RollLog)] : ''))
  }
}

export { Main }
