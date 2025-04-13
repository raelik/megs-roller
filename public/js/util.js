var Util = {
  login: null,
  data: {}, 
  set_data: (d) => { Util.data = d },
  has_data: function() {
    return Object.keys(Util.data).length !== 0
  },
  show_roll: function() {
    return !Util.login.processing && !Util.data.last_roll
  },
  show_log: function() {
    return Util.login.logged_in()
  },
  show_reroll: function() {
    if(Util.show_submit() && Util.data.last_roll) {
      return Util.data.last_roll[0] == Util.data.last_roll[1]
    }
  },
  show_submit: function() {
    return Util.has_data() && Util.data.success === undefined
  },
  show_resolve: function() {
    return Util.show_effect_fields() && !Util.data.resolved
  },
  show_break: function() {
    return (Util.show_roll() || Util.show_reroll()) && (Util.show_submit() || Util.show_resolve())
  },
  show_result: function() {
    return Util.has_data() && Util.data.success !== undefined
  },
  show_effect_fields: function() {
    return Util.has_data() && Util.data.success
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
  },
  get_cookie: function(name) {
    var dc = document.cookie
    var prefix = name + "="
    var begin = dc.indexOf("; " + prefix)
    if (begin == -1) {
        begin = dc.indexOf(prefix)
        if (begin != 0) return null
    }
    else
    {
        begin += 2
        var end = document.cookie.indexOf(";", begin)
        if (end == -1) {
        end = dc.length
        }
    }
    return decodeURIComponent(dc.substring(begin + prefix.length, end))
  },
  do_get_request: function(url, headers, params, cb, final_cb) {
    var root = document.body
    root.style.cursor = "wait"

    Promise.all([
      m.request({
        method: "GET",
        url: url,
        headers: headers,
        params: params
      })
      .then(function(d) {
        if(cb) { cb(d) }
      })
    ])
    .catch(err => null)
    .finally(function() {
      if(url != '/roll_log') { Util.login.last_request = Date.now() }
      if(final_cb) { final_cb() }
      root.style.cursor = "auto"
    })
  }
}

export { Util }
