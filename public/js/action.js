var Action = {
  data: {},
  doubles: function() {
    if(Action.data.last_roll) {
      return Action.data.last_roll[0] == Action.data.last_roll[1]
    }
  },
  get_action_fields: function() {
    var av    = document.getElementById('av')
    var ov    = document.getElementById('ov')
    var ov_cs = document.getElementById('ov_cs')
    return { av: av.value, ov: ov.value, ov_cs: ov_cs.value }
  },
  get_effect_fields: function() {
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
    var params = Action.get_action_fields()
    if(reroll) {
      params.reroll = true
    }

    Action.do_get_request('/action_roll', params)
  },
  result: function(e) {
    var params = Action.get_action_fields()
    params.result = true

    Action.do_get_request('/action_roll', params)
  },
  clear: function(e) {
    var params = { clear: true }

    Action.do_get_request('/action_roll', params)
  }
}

var ActionDataView = {
  view: function(e) {
    var data = Action.data
    return Object.keys(data).length === 0 ? [] : [
      m(".pure-u-1-3.centered", "Total Rolled: "+data.total, m("br"), "Last Roll: "+data.last_roll.join(', ')),
      m(".pure-u-1-3.centered", "Target Number: "+data.target),
      m(".pure-u-1-3.centered", "Column Shifts: "+data.cs),
    ]
  }
}

export { Action, ActionDataView }
