///|
fn main {
  let template_source =
    #|Subject: Welcome, {{ user.name | upper }}
    #|
    #|Hello {{ user.name }},
    #|
    #|{% if trial_active %}Your trial is active for {{ trial_days }} more days.{% else %}Your subscription is inactive.{% endif %}
    #|
    #|Recommended next steps:
    #|{% for step in next_steps %}- {{ step }}
    #|{% endfor %}
    #|Support: {{ support_email }}
  let output = try {
    let template = @mold.Template::parse(template_source)
    template.render(
      @mold.object({
        "user": @mold.object({ "name": @mold.string("Alice") }),
        "trial_active": @mold.bool(true),
        "trial_days": @mold.int(14),
        "next_steps": @mold.array([
          @mold.string("Complete your profile"),
          @mold.string("Invite your team"),
          @mold.string("Create your first dashboard"),
        ]),
        "support_email": @mold.string("support@example.com"),
      }),
    )
  } catch {
    _ => "render failed"
  }
  println(output)
}
