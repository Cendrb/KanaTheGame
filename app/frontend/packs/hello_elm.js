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
  let app = Elm.Main.init({
    node: target
  });

  createChannel('MatchChannel', {
    connected: () => {},
    disconnected: () => {},
    received: (data) => {
      console.log(data);
      const {mode} = data;
      switch(mode) {
        case 'set_state':
          app.ports.statePort.send(data.state);
          app.ports.signupsPort.send(JSON.parse(data.signups).map(signup => {
            return {...signup, color: {
              r: parseInt(signup.color.substring(1, 3), 16),
              g: parseInt(signup.color.substring(3, 5), 16), 
              b: parseInt(signup.color.substring(5, 7), 16)}
            };
          }));
          break;
        case 'set_mode':
          if(data.target_user_id === current_user_id || data.target_user_id === -1) {
            app.ports.rolePort.send({role: data.player_mode, user_id: current_user_id});
          }
          break;
        case 'board_render':
          if(data.target_user_id === current_user_id || data.target_user_id === -1) {
            console.log();
            console.log();
            app.ports.boardPort.send({board_data: JSON.parse(data.board_data), fulfilled_shapes: JSON.parse(data.fulfilled_shapes).map(shape => {
              return {...shape, board_data: JSON.parse(shape.board_data)};
            })});
          }
          break;
      }
    }
  });
});
