import { Util } from "/js/util.js"
import { Action } from "/js/action.js"

var Login = {
  enabled: false,
  data: {},
  processing: false,
  end_processing: () => { Login.processing = false },
  logged_in: () => { return Util.get_cookie('sess') },
  is_admin: () => { return Login.logged_in() && Login.data?.user?.admin },
  timeout_interval: null,
  last_request: null,
  logging: true,
  discord: true,
  setup_timeout: function() {
    // Run the check every 2 minutes
    if(Login.timeout_interval == null) {
      Login.timeout_interval = setInterval(Login.check_timeout, 120000)
    }
  },
  clear_timeout: function() {
    if(Login.timeout_interval) { clearInterval(Login.timeout_interval) }
  },
  check_timeout: function() {
    // Time out after 10 minutes of inactivity
    if((Date.now() - Login.last_request) > 600000) {
      Login.logout(true)
    }
  },
  setup: function() {
    Util.login = Login
    Login.processing = true
    Util.do_get_request('/login', {}, {}, function(data) {
      if(data.enabled) {
        Login.enabled = true
        if(data.session) {
          Login.data = data.session
          Login.logging = Login.data.logging
          Login.discord = Login.data.discord
          Login.setup_timeout()
        }
      }
      Login.end_processing()
    })
  },
  do_timeout: function() {
    Action.do_logout()
    m.redraw()
  },
  do_login_request: function(body, cb, final_cb) {
    var root = document.body
    root.style.cursor = "wait"

    Promise.all([
      m.request({
        method: "POST",
        url: "/login",
        body: body,
        headers: { 'Content-Type': 'application/json' }
      })
      .then(function(data) {
        Login.data = data
        if(cb) { cb(data) }
      })
    ])
    .catch(function(err) {
      if(err.code == 401) {
        var creds = ['username','password'].map((id) => { return document.getElementById(id) })
        creds.forEach((e) => { e.classList.add('alert') })
        setTimeout(function() {
          creds.forEach(function(e) {
            e.classList.add('fade')
            e.classList.remove('alert')
          })
          setTimeout(function() {
            creds.forEach((e) => { e.classList.remove('fade') })
          }, 1000)
        }, 250)
      }
    })
    .finally(function() {
      if(final_cb) { final_cb() }
      root.style.cursor = "auto"
    })
  },
  login: function(e) {
    if(Login.enabled && !Login.processing) {
      Login.processing = true
      Action.clear(null, function() {
        var user = document.getElementById('username')
        var pass = document.getElementById('password')
        Login.do_login_request({ u: user.value, p: pass.value }, Login.setup_timeout, Login.end_processing)
      })
    }
  },
  logout: function(e) {
    if(!Login.processing) {
      Login.processing = true
      Action.clear(null, function() {
        Login.data = {}
        Login.discord = true
        Login.logging = true
        // e is normally an Event, but during a login timeout, it's used as a boolean to indicate
        // that the Login.do_timeout callback should be used. It calls Action.do_logout AND does
        // a redraw. This is necessary because a timeout happens outside of the Mithril context.
        Util.do_get_request('/logout', {}, {}, Login.clear_timeout, (e === true ? Login.do_timeout : Action.do_logout))
      })
    }
  },
  center_line_height: function(vnode) {
    var nodes = vnode.dom.querySelectorAll('#login span')
    nodes.forEach((e) => { e.style.removeProperty('line-height') })

    var height = vnode.dom.querySelector('#login div').offsetHeight
    nodes.forEach((e) => {
      var divisor = Array.from(e.children).filter((e) => { return e.tagName == 'A' }).length
      e.style.lineHeight = (height / divisor) + "px"
    })
  }
}

var CharacterOptions = {
  view: function() {
    return Object.keys(Login.data.chars ?? {}).sort().map(function(char_id) {
      return m("option", { value: char_id }, Login.data.chars[char_id])
    })
  }
}

var LoginBarView = {
  oncreate: Login.center_line_height,
  onupdate: Login.center_line_height,
  view: function(e) {
    var large_screen = window.matchMedia('screen and (min-width: 500px)').matches
    return [m(".pure-u-5-5#login", !Login.logged_in() ?
      [m(".pure-u-3-4",
         m(".pure-u-1-2", "Username:", m("input#username", { type: 'text', size: large_screen ? 12 : 8 })),
         m(".pure-u-1-2", "Password:", m("input#password", { type: 'password', size: large_screen ? 12 : 8 }))),
       m(".pure-u-1-4.centered", m("span", m("a.pure-button", { onclick: Login.login }, "Login")))] : 
      [m(".pure-u-3-4", "Roll As:", m("select#character", !Util.show_roll() ? { disabled: true } : {}, m(CharacterOptions))),
       m(".pure-u-1-4.centered", m("span", m("a.pure-button", { onclick: Login.logout }, "Logout")))]
    )]
  }
}

export { Login, LoginBarView }
