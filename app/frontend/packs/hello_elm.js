// Run this example by adding <%= javascript_pack_tag "hello_elm" %> to the
// head of your layout file, like app/views/layouts/application.html.erb.
// It will render "Hello Elm!" within the page.

import {
  Elm
} from '../Main';

import createChannel from '../createChannel';

document.addEventListener('DOMContentLoaded', () => {
  const target = document.getElementById('elm-test');
  const current_user_id = parseInt(target.dataset.current_user_id);

  let channel;
  let app;
  let flags = {};

  const trySetupApp = () => {
    if(flags.state && flags.signups && flags.role && flags.board) {
      app = Elm.Main.init({
        node: target,
        flags
      });
  
      app.ports.playPort.subscribe(data => {
        channel.play(data);
      });

      document.getElementById("repopulate_button").addEventListener("click", () => {
        channel.repopulate();
      });
    }
  };

  const updateState = (data) => {
    if(app) {
      app.ports.statePort.send(data);
    }
    else {
      flags.state = data;
      trySetupApp();
    }
  };

  const updateRole = (data) => {
    if(app) {
      app.ports.rolePort.send(data);
    }
    else {
      flags.role = data;
      trySetupApp();
    }
  };

  const updateSignups = (data) => {
    if(app) {
      app.ports.signupsPort.send(data);
    }
    else {
      flags.signups = data;
      trySetupApp();
    }
  };

  const updateBoard = (data) => {
    if(app) {
      app.ports.boardPort.send(data);
    }
    else {
      flags.board = data;
      trySetupApp();
    }
  };

  channel = createChannel('MatchChannel', {
    connected: () => {},
    disconnected: () => {},
    received: (data) => {
      console.log(data);
      const {mode} = data;
      switch(mode) {
        case 'set_state':
          updateState(data.state);
          updateSignups(JSON.parse(data.signups).map(signup => {
            return {...signup, color: {
              r: parseInt(signup.color.substring(1, 3), 16),
              g: parseInt(signup.color.substring(3, 5), 16), 
              b: parseInt(signup.color.substring(5, 7), 16)}
            };
          }));
          break;
        case 'set_mode':
          if(data.target_user_id === current_user_id || data.target_user_id === -1) {
            updateRole({role: data.player_mode, player_id: data.player_id});
          }
          break;
        case 'board_render':
          if(data.target_user_id === current_user_id || data.target_user_id === -1) {
            updateBoard({board_data: JSON.parse(data.board_data), fulfilled_shapes: JSON.parse(data.fulfilled_shapes).map(shape => {
              return {...shape, board_data: JSON.parse(shape.board_data), color: {
                r: parseInt(shape.color.substring(1, 3), 16),
                g: parseInt(shape.color.substring(3, 5), 16), 
                b: parseInt(shape.color.substring(5, 7), 16)}
              };
            }), currently_playing: data.currently_playing});
            updateSignups(JSON.parse(data.signups).map(signup => {
              return {...signup, color: {
                r: parseInt(signup.color.substring(1, 3), 16),
                g: parseInt(signup.color.substring(3, 5), 16), 
                b: parseInt(signup.color.substring(5, 7), 16)}
              };
            }));
          }
          break;
      }
    },
    play: function (data) {
      return this.perform("play", { sourceX: data.from.x, sourceY: data.from.y, targetX: data.to.x, targetY: data.to.y });
    },
    repopulate: function (data) {
      return this.perform("repopulate");
    }
  });
});
