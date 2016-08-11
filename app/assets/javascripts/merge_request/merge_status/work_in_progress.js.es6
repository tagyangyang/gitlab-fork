const workInProgress = {
  props: ['ci', 'mergeRequest', 'project'],
  template: `<div>
              <h4>
                This merge request is currently a Work In Progress
              </h4>
              <p>
                When this merge request is ready,
                <a rel="nofollow" href="{{mergeRequest.removeWipUrl}}">remove the
                <code>WIP:</code>
                prefix from the title
                </a>to allow it to be merged.
              </p>
            </div>`
};
