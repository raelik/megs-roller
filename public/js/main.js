import { Action, ActionDataView } from "/js/action.js"
var Main = {
  action: Action,
  view: function(e) {
    return [ m(".pure-g",
      m(".pure-u-2-5", m("h1", "MEGS Dice Roller")),
      m(".pure-u-3-5", m("a.pure-button", { onclick: Action.clear }, "Clear")),
      m(".pure-u-2-5",
        m(".pure-u-1-3.centered", "AV"),
        m(".pure-u-1-3.centered", "OV"),
        m(".pure-u-1-3.centered", "OV CS Bonus/Penalty(-)"),
      ),
      m(".pure-u-3-5"),
      m(".pure-u-2-5",
        m(".pure-u-1-3.centered", m("input", { type: 'text', id: 'av', size: 3, minlength: 1, maxlength: 3 })),
        m(".pure-u-1-3.centered", m("input", { type: 'text', id: 'ov', size: 3, minlength: 1, maxlength: 3 })),
        m(".pure-u-1-3.centered", m("input", { type: 'text', id: 'ov_cs', size: 3, minlength: 1, maxlength: 3 })),
      ),
      m(".pure-u-3-5",
        Action.data.last_roll ? m("", { style: "display: none" }) : m("a.pure-button", { id: 'roll', onclick: Action.roll }, "Roll"),
        Action.doubles() ? m("a.pure-button", { id: 'reroll', onclick: Action.roll }, "Reroll") : m("", { style: "display: none" })
      ),
      m(".pure-u-2-5", m(ActionDataView)),
      m(".pure-u-3-5", Action.data ? m("a.pure-button", { onclick: Action.result }, "Submit") : m("", { style: "display: none" })),
    )]
  }
}

export { Main }
