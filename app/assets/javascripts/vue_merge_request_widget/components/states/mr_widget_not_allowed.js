export default {
  name: 'MRWidgetNotAllowed',
  template: `
    <div class="mr-widget-body">
      <button class="btn btn-success btn-small" disabled="disabled">Merge</button>
      <span class="bold">
        Ready to be merged automatically.
        Ask someone with write access to this repository to merge this request.
      </span>
    </div>
  `,
};
