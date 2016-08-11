const userNotAllowed = {
  props: ['ci', 'mergeRequest'],
  template: `<h4>Ready to be merged automatically</h4>
            <p>
              Ask someone with write access to this repository to merge this request.
              <span v-if="mergeRequest.forceRemoveSourceBranch">
                The source branch will be removed.
              </span>
            </p>
            `
};
