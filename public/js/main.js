import { Action, ActionClearButton, ActionRollButtons,
   ActionDataView, ActionResolvedView } from "/js/action.js"

var Main = {
  action: Action,
  onupdate: function(vnode) {
    var viewport = document.querySelector('meta[name="viewport"]');

    if ( viewport ) {
      viewport.content = 'initial-scale=1';
      viewport.content = 'width=device-width';
    }
  },
  text_field_attrs: function(id) {
    return { id: id, type: 'text', size: 3, minlength: 1, maxlength: 3 }
  },
  action_field_attrs: function(id) {
    var attrs = Main.text_field_attrs(id)
    return Object.assign(attrs, (!Action.has_data() || Action.data.success === undefined) ? {} : { disabled: true })
  },
  result_style: function() {
    var style = !Action.has_data() || Action.data.success === undefined ? "display: none" : ""
    if(Action.has_data() && Action.data.success !== undefined) {
      style = "text-align: center; margin-bottom: 10px; color: white; background-color: " +
              (Action.data.success ? "green" : "red")
    }
    return style
  },
  result_text: function() {
    var text = ""
    if(Action.has_data() && Action.data.success !== undefined) {
      text = "Action " + (Action.data.success ? "Succeeded!" : "FAILED.")
    }
    return text
  },
  resolve_style: function() {
    return Action.has_data() && Action.data.success ? "" : "display: none"
  },
  view: function(e) {
    var check = Main.check_action_field
    return [ m(".pure-g",
      m(".pure-u-1-4.centered", m(ActionClearButton)),
      m(".pure-u-1-2.centered", m("h2", "MEGS Dice Roller")),
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
      m(".pure-u-5-5", { style: Main.resolve_style() },
        m(".pure-u-1-3.centered", "EV"),
        m(".pure-u-1-3.centered", "RV"),
        m(".pure-u-1-3.centered", "RV CS"),
      ),
      m(".pure-u-5-5", { style: Main.resolve_style() },
        m(".pure-u-1-3.centered", m("input", Main.text_field_attrs('ev'))),
        m(".pure-u-1-3.centered", m("input", Main.text_field_attrs('rv'))),
        m(".pure-u-1-3.centered", m("input", Main.text_field_attrs('rv_cs')))
      ),
      m(ActionResolvedView)
    )]
  }
}

export { Main }
