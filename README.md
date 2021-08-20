# Istio Katas

Exercises for the [Eficode Academy](https://www.eficode.com/academy) Istio course.

## Exercise Overview

The natural order would be:

- [Introducing the setup](000-setup-introduction.md)
- [Basic traffic routing](001-basic-traffic-routing.md)
- [Deployment patterns](002-deployment-patterns.md)
- [Traffic into the mesh](003-ingress-traffic.md)
- [Traffic out of the mesh](004-egress-traffic.md)
- [Securing with mutual TLS](005-securing-with-mtls.md)
- [Service access control](006-service-access-control.md)
- [A tour of Istio's metrics](007-istio-metrics-tour.md) - In Progress
- [Observe network delays](008-observe-network-delays) - In Progress

However each exercise, besides the setup introduction, has a 
start folder located beneath it. E.g. `001-basic-traffic-routing/start` that 
allows you to do them in **your** preferred order. 

> :bulb: If you do **not** start with [Introducing the setup](000-setup-introduction.md) 
> you will need to enable automatic sidecar injection.

Do note that there can be multiple exercises per exercise file. 

## How to Read Exercise Files

All exercise files start with an introduction
followed by the actual exercise(s).

A general overview of the exercise(s) is given first, followed by more 
detailed step-by-step instructions. If you want a challenge, you can try 
to read the general steps of the exercise and do the exercise. In general 
it is recommended to do the **step-by-step** instructions. The step-by-step 
instructions also explain _why_ some of the steps are done in the way they 
are in the exercise.

**Each exercise is summarized in bold text at the
beginning.**

- All exercise steps are bulleted. The bulleted points summarize the previous 
paragraphs as small individual tasks. **To finish the exercise, it's 
sufficient to read only the bulleted steps.** All other text is just narrative 
and explanations as to why things are done the way they are.

> Quoted blocks indicate points that are "nice to know" and can be safely 
> ignored. They won't affect the outcome of the exercise, but generally 
> include additional information the training doesn't handle.
>
> :bulb: If a quoted paragraph begins with a lightbulb, it indicates that 
> it's a hint for the exercise step.
