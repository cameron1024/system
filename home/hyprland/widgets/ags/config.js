const powerProfiles = await Service.import('powerProfiles');

const currentProfile = Widget.Label({
  label: powerProfiles.bind('active_profile'),
})

const togglePowerProfileButton = Widget.Button({
  on_clicked: () => {
    switch(powerProfiles.active_profile) {
      case 'balanced':
        powerProfiles.active_profile = 'performance';
        break;
      default:
        powerProfiles.active_profile = 'balanced';
        break;
    }
  }
})

function Panel(monitor = 0) {

  const myLabel = Widget.Label({
    label: "some example content",
  })

  const myPanel = Widget.Window({
    name: "panel",
    anchor: ["top", "right", "bottom"],
    child: Widget.Box({
      spacing: 10,
      homogenous: false,
      vertical: true,
      children: [
        myLabel,
        togglePowerProfileButton,
      ],
    }),
  })
}

App.config({
  windows: [
    Panel()
  ]
})
