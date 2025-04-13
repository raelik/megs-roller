import { Util } from "/js/util.js"

var Log = {
  data: {},
  idx: [],
  processing: false,
  interval: null,
  init_data: (l) => { Log.set_data(false, l) },
  update_data: function(l) {
    Log.set_data(true, l)
    m.redraw()
  },
  set_data: function(update, l) {
    l.forEach((r) => { Log.data[r.hash_key] = r })
    if(update) {
      l.map(r => r.hash_key).forEach(r => Log.idx.unshift(r))
    } else {
      Log.idx = l.map(r => r.hash_key)
    }

    if(update && Log.idx.length > 50) {
      var last = null
      while(Log.idx.length > 50) {
        if(last = Log.selected) {
          document.getElementById('log_close').click()
        }
        last = Log.idx.pop()
        delete Log.data[last]
      }
    }
    Log.processing = false
  },
  do_logout: function() {
    clearInterval(Log.interval)
    Log.processing = true
    Log.interval = null
    Log.selected = null
    Log.idx = []
    Log.data = {}
    Log.processing = false
  },
  get_roll_log: function(latest, cb) {
    if(Util.login.logged_in()) {
      /* This should only get triggered if someone logs out JUST after the logged-in condition
       * was checked and the clear_log function is executing. It could TECHNICALLY happen if a
       * /roll_log request takes longer than 5 seconds, but I really don't see this happening.
       */
      if(Log.processing === true) {
        window.setTimeout(Log.get_roll_log, 100, latest, cb); /* this checks the flag every 100 milliseconds*/
      } else {
        Log.processing = true
        var key = Log.idx[0]
        var headers = (latest && key ? { 'X-MEGS-Search-Key': Log.data[key].search_key } : {})
        Util.do_get_request('/roll_log', headers, {}, (latest ? Log.update_data : Log.init_data), cb)
      }
    } else if(Log.interval) {
      clearInterval(Log.interval)
    }
  },
  set_modal_height: function(vnode) {
    var roll_log = vnode.dom
    var modal    = roll_log.children[0]
    modal.style.height = roll_log.offsetTop + 'px'
  },
  setup_log_row: function(vnode) {
    vnode.dom.removeEventListener('log_click', Log.show_detail)
    vnode.dom.addEventListener('log_click', Log.show_detail)
  },
  start_log: function(vnode) {
    Log.get_roll_log(false, function() {
      if(Util.login.logged_in()) {
        Log.interval = setInterval(Log.get_roll_log, 5000, true);
      }
    })
  },
  show_detail: function(e, manual_redraw) {
    if(Log.processing === true) {
      e.redraw = false
      window.setTimeout(Log.show_detail, 100, e, true); /* this checks the flag every 100 milliseconds*/
    } else {
      if(e.target.id != 'roll_log' && e.target) {
        var target   = (e.target.id == '' ? e.target.parentElement : e.target)
        var roll_log = target.parentElement
        var detail   = target.parentElement.children[0].children[0]
        Log.reposition_detail(detail)
        if(Log.selected) { roll_log.children[Log.selected].classList.remove('selected') }
        Log.selected = target.id
        e.target.classList.add('selected')

        Util.login.last_request = Date.now()
        document.activeElement.blur()
        if(manual_redraw) { m.redraw() }
      }
    }
  },
  reposition_detail: function(detail) {
    var modal    = detail.parentElement
    var roll_log = modal.parentElement
    if(Log.selected) {
      var height = detail.offsetHeight
      detail.style.width = (roll_log.offsetWidth - 25) + 'px'
      detail.style.top   = (roll_log.offsetTop - height - 5) + 'px';
      modal.style.zIndex = '1'
    } else {
      modal.style.zIndex = '-1'
    }
  },
  close_detail: function(e) {
    e.stopPropagation()
    if(e.target == modal || e.target == log_close) {
      Log.selected = null
    }
  },
  do_toggle: function(d) {
    ['logging', 'discord'].forEach(function(k) {
      if(k in this) {
        Util.login.data[k] = d.session[k]
        Util.login[k] = d.session[k]
      }
    })
  },
  toggle: function(e, manual_redraw) {
    var button = (e.target.id == 'log_toggle' ? 'logging' : 'discord')
    if(button == 'discord' || Util.login.is_admin()) {
      if(Log.processing === true) {
        e.redraw = false
        window.setTimeout(Log.toggle, 100, e, true); /* this checks the flag every 100 milliseconds*/
      } else {
        var params = {}
        Util.login[button] = !Util.login[button];
        params[button.charAt(0)] = Util.login[button]
        Util.do_get_request('/login', {}, params, (manual_redraw ? function(d) {
          Log.do_toggle(d)
          m.redraw()
        } : Log.do_toggle))
      }
    }
  }
}

var LogDetail = {
  onupdate: (v) => Log.reposition_detail(v.dom),
  view: function(vnode) {
    var detail_table = []
    if(Log.selected) {
      var r       = Log.data[Log.selected]
      var mark_cl = r.success ? "success" : "failure"
      var mark    = r.success ? "&#x2611;" : "&#x2612;"
      detail_table = [m("table",
                        m("tr", m("td.hd", "Timestamp"), m("td#timestamp", r.timestamp), m("td#log_close","❌"))),
                      m("table",
                        m("tr", m("td.hd", "Character"), m("td", r.character), m("td.hd2", "Owner"), m("td", r.owner)),
                        m("tr", m("td.hd", "User"), m("td", r.user),
                                m("td.hd2", "AV/OV"),
                                m("td", r.av + ' / ' + r.ov + (r.ov_cs ? ' (' + r.ov_cs + ')' : ''))),
                        m("tr", m("td.hd", "Target"), m("td", r.target), m("td.hd2", "Total"), m("td", r.total)),
                        m("tr", m("td.hd", "Success"), m("td."+mark_cl, m.trust(mark)), m("td.hd2", "Rolls"),
                                m("td", r.rolls.flat().join(', '))),
                        m("tr", m("td.hd", "CS"), m("td", r.cs),
                                m("td.hd2", "EV/RV"),
                                m("td", (r.ev == null ? '' : r.ev + ' / ' + r.rv) + (r.rv_cs ? ' (' + r.rv_cs + ')' : ''))),
                        m("tr", m("td.hd", "RAPs"), m("td", { colspan: 3 }, r.raps)))]
    }
    return m("#log_detail", detail_table)
  }
}

var LogRow = {
  oncreate: Log.setup_log_row,
  view: function(vnode) {
    var key  = vnode.attrs.hash_key
    var roll = Log.data[key]
    var mark_cl     = roll.success ? "success" : "failure"
    var mark        = roll.success ? " &#x2611;" : " &#x2612;"
    var post_fields = roll.success ? ', ' +
      ['CS: ' + roll.cs, 'E/R: ' + roll.ev + '/' + roll.rv + (roll.rv_cs ? (' (' + roll.rv_cs + ')') : ''), 'RAPs: ' + roll.raps].join(', ') : ''
    var pre_fields  = [roll.character ? (roll.character + ' (' + roll.user + ')') : roll.user,
                       'A/O: ' + roll.av + '/' + roll.ov + (roll.ov_cs ? (' (' + roll.ov_cs + ')') : ''),
                       roll.total + " v " + roll.target].join(', ')

    return m("span.log_row"+(Log.selected == key ? '.selected' : ''), { key: key, id: key },
             pre_fields, m("span."+mark_cl, m.trust(mark)), post_fields, m("br"))
  }
}

var RollLog = {
  oninit: Log.start_log,
  oncreate: Log.set_modal_height,
  onupdate: function(vnode) {
    var e = vnode.dom
    e.style.height = (window.innerHeight - e.offsetTop) + 'px'
  },
  view: function(vnode) {
    return m(".pure-u-5-5#roll_log", { onclick: Log.show_detail },
             m("#modal", { onclick: Log.close_detail }, m(LogDetail)),
             Log.idx.map(k => m(LogRow, { hash_key: k })))
  }
}

var LogToggle = {
  view: function(vnode) {
    return m('img#log_toggle.'+(Util.login.logging ? '' : 'disabled'), { src: '/img/log.png', onclick: Log.toggle })
  }
}

var DiscordToggle = {
  view: function(vnode) {
    return m('img#discord_toggle.'+(Util.login.discord ? '' : 'disabled'), { src: '/img/discord.png', onclick: Log.toggle })
  }
}

export { Log, RollLog, LogToggle, DiscordToggle }
