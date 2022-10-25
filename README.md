# Istio Katas

Exercises for the [Eficode Academy](https://www.eficode.com/academy) Istio course.

## Exercise Overview

The natural order would be:

- [Introducing the setup](00-setup-introduction.md)
- [Basic traffic routing](01-basic-traffic-routing.md)
- [Deployment patterns](02-deployment-patterns.md)
- [Traffic into the mesh](03-ingress-traffic.md)
- [Traffic out of the mesh](04-egress-traffic.md)
- [Securing with mutual TLS](05-securing-with-mtls.md)
- [Service access control](06-service-access-control.md)
- [A tour of Istio's metrics](07-istio-metrics-tour.md)
- [Istio and distributed tracing](08-distributed-tracing.md)

However each exercise **file** should be complete enough to allow you to
do them in **your** preferred order.

There is a corresponding (numbered) directory for each exercise file. The
kubernetes yaml will working with will be located here so you can view them.

> :bulb: If you do **not** start with [Introducing the setup](00-setup-introduction.md)
> you will need to enable automatic sidecar injection prior to doing the exercise.

Do note that there **can be multiple exercises** per exercise file.

## How to Read Exercise Files

All exercise files start with an overall introduction followed by the actual
exercise(s). Each exercise will have a more detailed introduction to the
specific exercise.

**Each exercise is summarized in bold text at the beginning.**

A general overview is given first as a bulleted list to give you an
idea as to what you will be doing.

This is followed by a detailed step-by-step set of **tasks** you execute
to complete the exercise. The tasks should be executed from a terminal in
the **root** directory, e.g. `istio-katas`.

> :bulb: The actual tasks in the **Step by Step** section are **collapsed**.
> Select the arrow to **expand** the tasks section to do the exercise.

The step-by-step instructions also explain _why_ some of the steps are
done in the way they are in the exercise.

> Quoted blocks indicate points that are "nice to know" and can be safely
> ignored. They won't affect the outcome of the exercise, but generally
> include additional nuggets information.
>
> :bulb: If a quoted paragraph begins with a lightbulb, it indicates that
> it's a hint for the exercise step.
