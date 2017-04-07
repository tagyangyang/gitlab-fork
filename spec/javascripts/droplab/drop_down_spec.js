/* eslint-disable */

import DropDown from '~/droplab/drop_down';
import utils from '~/droplab/utils';
import { SELECTED_CLASS } from '~/droplab/constants';

describe('DropDown', function () {
  describe('class constructor', function () {
    beforeEach(function () {
      spyOn(DropDown.prototype, 'getItems');
      spyOn(DropDown.prototype, 'initTemplateString');
      spyOn(DropDown.prototype, 'addEvents');

      this.list = { innerHTML: 'innerHTML' };
      this.dropdown = new DropDown(this.list);
    });

    it('sets the .hidden property to true', function () {
      expect(this.dropdown.hidden).toBe(true);
    })

    it('sets the .list property', function () {
      expect(this.dropdown.list).toBe(this.list);
    });

    it('calls .getItems', function () {
      expect(DropDown.prototype.getItems).toHaveBeenCalled();
    });

    it('calls .initTemplateString', function () {
      expect(DropDown.prototype.initTemplateString).toHaveBeenCalled();
    });

    it('calls .addEvents', function () {
      expect(DropDown.prototype.addEvents).toHaveBeenCalled();
    });

    it('sets the .initialState property to the .list.innerHTML', function () {
      expect(this.dropdown.initialState).toBe(this.list.innerHTML);
    });

    describe('if the list argument is a string', function () {
      beforeEach(function () {
        this.element = {};
        this.selector = '.selector';

        spyOn(Document.prototype, 'querySelector').and.returnValue(this.element);

        this.dropdown = new DropDown(this.selector);
      });

      it('calls .querySelector with the selector string', function () {
        expect(Document.prototype.querySelector).toHaveBeenCalledWith(this.selector);
      });

      it('sets the .list property element', function () {
        expect(this.dropdown.list).toBe(this.element);
      });
    });
  });

  describe('getItems', function () {
    beforeEach(function () {
      this.list = { querySelectorAll: () => {} };
      this.dropdown = { list: this.list };
      this.nodeList = [];

      spyOn(this.list, 'querySelectorAll').and.returnValue(this.nodeList);

      this.getItems = DropDown.prototype.getItems.call(this.dropdown);
    });

    it('calls .querySelectorAll with a list item query', function () {
      expect(this.list.querySelectorAll).toHaveBeenCalledWith('li');
    });

    it('sets the .items property to the returned list items', function () {
      expect(this.dropdown.items).toEqual(jasmine.any(Array));
    });

    it('returns the .items', function () {
      expect(this.getItems).toEqual(jasmine.any(Array));
    });
  });

  describe('initTemplateString', function () {
    beforeEach(function () {
      this.items = [{ outerHTML: '<a></a>' }, { outerHTML: '<img>' }];
      this.dropdown = { items: this.items };

      DropDown.prototype.initTemplateString.call(this.dropdown);
    });

    it('should set .templateString to the last items .outerHTML', function () {
      expect(this.dropdown.templateString).toBe(this.items[1].outerHTML);
    });

    it('should not set .templateString to a non-last items .outerHTML', function () {
      expect(this.dropdown.templateString).not.toBe(this.items[0].outerHTML);
    });

    describe('if .items is not set', function () {
      beforeEach(function () {
        this.dropdown = { getItems: () => {} };

        spyOn(this.dropdown, 'getItems').and.returnValue([]);

        DropDown.prototype.initTemplateString.call(this.dropdown);
      });

      it('should call .getItems', function () {
        expect(this.dropdown.getItems).toHaveBeenCalled();
      });
    });

    describe('if items array is empty', function () {
      beforeEach(function () {
        this.dropdown = { items: [] };

        DropDown.prototype.initTemplateString.call(this.dropdown);
      });

      it('should set .templateString to an empty string', function () {
        expect(this.dropdown.templateString).toBe('');
      });
    });
  });

  describe('clickEvent', function () {
    beforeEach(function () {
      this.list = { dispatchEvent: () => {} };
      this.dropdown = { hide: () => {}, list: this.list, addSelectedClass: () => {} };
      this.event = { preventDefault: () => {}, target: 'target' };
      this.customEvent = {};
      this.closestElement = {};

      spyOn(this.dropdown, 'hide');
      spyOn(this.dropdown, 'addSelectedClass');
      spyOn(this.list, 'dispatchEvent');
      spyOn(this.event, 'preventDefault');
      spyOn(window, 'CustomEvent').and.returnValue(this.customEvent);
      spyOn(utils, 'closest').and.returnValues(this.closestElement, undefined);

      DropDown.prototype.clickEvent.call(this.dropdown, this.event);
    });

    it('should call utils.closest', function () {
      expect(utils.closest).toHaveBeenCalledWith(this.event.target, 'LI');
    });

    it('should call addSelectedClass', function () {
      expect(this.dropdown.addSelectedClass).toHaveBeenCalledWith(this.closestElement);
    })

    it('should call .preventDefault', function () {
      expect(this.event.preventDefault).toHaveBeenCalled();
    });

    it('should call .hide', function () {
      expect(this.dropdown.hide).toHaveBeenCalled();
    });

    it('should construct CustomEvent', function () {
      expect(window.CustomEvent).toHaveBeenCalledWith('click.dl', jasmine.any(Object));
    });

    it('should call .dispatchEvent with the customEvent', function () {
      expect(this.list.dispatchEvent).toHaveBeenCalledWith(this.customEvent);
    });

    describe('if no selected element exists', function () {
      beforeEach(function () {
        this.event.preventDefault.calls.reset();
        this.clickEvent = DropDown.prototype.clickEvent.call(this.dropdown, this.event);
      });

      it('should return undefined', function () {
        expect(this.clickEvent).toBe(undefined);
      });

      it('should return before .preventDefault is called', function () {
        expect(this.event.preventDefault).not.toHaveBeenCalled();
      });
    });
  });

  describe('addSelectedClass', function () {
    beforeEach(function () {
      this.items = Array(4).forEach((item, i) => {
        this.items[i] = { classList: { add: () => {} } };
        spyOn(this.items[i].classList, 'add');
      });
      this.selected = { classList: { add: () => {} } };
      this.dropdown = { removeSelectedClasses: () => {} };

      spyOn(this.dropdown, 'removeSelectedClasses');
      spyOn(this.selected.classList, 'add');

      DropDown.prototype.addSelectedClass.call(this.dropdown, this.selected);
    });

    it('should call .removeSelectedClasses', function () {
      expect(this.dropdown.removeSelectedClasses).toHaveBeenCalled();
    });

    it('should call .classList.add', function () {
      expect(this.selected.classList.add).toHaveBeenCalledWith(SELECTED_CLASS);
    });
  });

  describe('removeSelectedClasses', function () {
    beforeEach(function () {
      this.items = Array(4);
      this.items.forEach((item, i) => {
        this.items[i] = { classList: { add: () => {} } };
        spyOn(this.items[i].classList, 'add');
      });
      this.dropdown = { items: this.items };

      DropDown.prototype.removeSelectedClasses.call(this.dropdown);
    });

    it('should call .classList.remove for all items', function () {
      this.items.forEach((item, i) => {
        expect(this.items[i].classList.add).toHaveBeenCalledWith(SELECTED_CLASS);
      });
    });

    describe('if .items is not set', function () {
      beforeEach(function () {
        this.dropdown = { getItems: () => {} };

        spyOn(this.dropdown, 'getItems').and.returnValue([]);

        DropDown.prototype.removeSelectedClasses.call(this.dropdown);
      });

      it('should call .getItems', function () {
        expect(this.dropdown.getItems).toHaveBeenCalled();
      });
    });
  });

  describe('addEvents', function () {
    beforeEach(function () {
      this.list = { addEventListener: () => {} };
      this.dropdown = { list: this.list, clickEvent: () => {}, eventWrapper: {} };

      spyOn(this.list, 'addEventListener');

      DropDown.prototype.addEvents.call(this.dropdown);
    });

    it('should call .addEventListener', function () {
      expect(this.list.addEventListener).toHaveBeenCalledWith('click', jasmine.any(Function));
    });
  });

  describe('toggle', function () {
    beforeEach(function () {
      this.dropdown = { hidden: true, show: () => {}, hide: () => {} };

      spyOn(this.dropdown, 'show');
      spyOn(this.dropdown, 'hide');

      DropDown.prototype.toggle.call(this.dropdown);
    });

    it('should call .show if hidden is true', function () {
      expect(this.dropdown.show).toHaveBeenCalled();
    });

    describe('if hidden is false', function () {
      beforeEach(function () {
        this.dropdown = { hidden: false, show: () => {}, hide: () => {} };

        spyOn(this.dropdown, 'show');
        spyOn(this.dropdown, 'hide');

        DropDown.prototype.toggle.call(this.dropdown);
      });

      it('should call .show if hidden is true', function () {
        expect(this.dropdown.hide).toHaveBeenCalled();
      });
    });
  });

  describe('setData', function () {
    beforeEach(function () {
      this.dropdown = { render: () => {} };
      this.data = ['data'];

      spyOn(this.dropdown, 'render');

      DropDown.prototype.setData.call(this.dropdown, this.data);
    });

    it('should set .data', function () {
      expect(this.dropdown.data).toBe(this.data);
    });

    it('should call .render with the .data', function () {
      expect(this.dropdown.render).toHaveBeenCalledWith(this.data);
    });
  });

  describe('addData', function () {
    beforeEach(function () {
      this.dropdown = { render: () => {}, data: ['data1'] };
      this.data = ['data2'];

      spyOn(this.dropdown, 'render');
      spyOn(Array.prototype, 'concat').and.callThrough();

      DropDown.prototype.addData.call(this.dropdown, this.data);
    });

    it('should call .concat with data', function () {
      expect(Array.prototype.concat).toHaveBeenCalledWith(this.data);
    });

    it('should set .data with concatination', function () {
      expect(this.dropdown.data).toEqual(['data1', 'data2']);
    });

    it('should call .render with the .data', function () {
      expect(this.dropdown.render).toHaveBeenCalledWith(['data1', 'data2']);
    });

    describe('if .data is undefined', function () {
      beforeEach(function () {
        this.dropdown = { render: () => {}, data: undefined };
        this.data = ['data2'];

        spyOn(this.dropdown, 'render');

        DropDown.prototype.addData.call(this.dropdown, this.data);
      });

      it('should set .data with concatination', function () {
        expect(this.dropdown.data).toEqual(['data2']);
      });
    });
  });

  describe('render', function () {
    beforeEach(function () {
      this.list = { querySelector: () => {} };
      this.dropdown = { renderChildren: () => {}, list: this.list };
      this.renderableList = {};
      this.data = [0, 1];

      spyOn(this.dropdown, 'renderChildren').and.callFake(data => data);
      spyOn(this.list, 'querySelector').and.returnValue(this.renderableList);
      spyOn(this.data, 'map').and.callThrough();

      DropDown.prototype.render.call(this.dropdown, this.data);
    });

    it('should call .map', function () {
      expect(this.data.map).toHaveBeenCalledWith(jasmine.any(Function));
    });

    it('should call .renderChildren for each data item', function() {
      expect(this.dropdown.renderChildren.calls.count()).toBe(this.data.length);
    });

    it('sets the renderableList .innerHTML', function () {
      expect(this.renderableList.innerHTML).toBe('01');
    });

    describe('if no data argument is passed' , function () {
      beforeEach(function () {
        this.data.map.calls.reset();
        this.dropdown.renderChildren.calls.reset();

        DropDown.prototype.render.call(this.dropdown, undefined);
      });

      it('should not call .map', function () {
        expect(this.data.map).not.toHaveBeenCalled();
      });

      it('should not call .renderChildren', function () {
        expect(this.dropdown.renderChildren).not.toHaveBeenCalled();
      });
    });

    describe('if no dynamic list is present', function () {
      beforeEach(function () {
        this.list = { querySelector: () => {} };
        this.dropdown = { renderChildren: () => {}, list: this.list };
        this.data = [0, 1];

        spyOn(this.dropdown, 'renderChildren').and.callFake(data => data);
        spyOn(this.list, 'querySelector');
        spyOn(this.data, 'map').and.callThrough();

        DropDown.prototype.render.call(this.dropdown, this.data);
      });

      it('sets the .list .innerHTML', function () {
        expect(this.list.innerHTML).toBe('01');
      });
    });
  });

  describe('renderChildren', function () {
    beforeEach(function () {
      this.templateString = 'templateString';
      this.dropdown = { setImagesSrc: () => {}, templateString: this.templateString };
      this.data = { droplab_hidden: true };
      this.html = 'html';
      this.template = { firstChild: { outerHTML: 'outerHTML', style: {} } };

      spyOn(utils, 't').and.returnValue(this.html);
      spyOn(document, 'createElement').and.returnValue(this.template);
      spyOn(this.dropdown, 'setImagesSrc');

      this.renderChildren = DropDown.prototype.renderChildren.call(this.dropdown, this.data);
    });

    it('should call utils.t with .templateString and data', function () {
      expect(utils.t).toHaveBeenCalledWith(this.templateString, this.data);
    });

    it('should call document.createElement', function () {
      expect(document.createElement).toHaveBeenCalledWith('div');
    });

    it('should set the templates .innerHTML to the HTML', function () {
      expect(this.template.innerHTML).toBe(this.html);
    });

    it('should call .setImagesSrc with the template', function () {
      expect(this.dropdown.setImagesSrc).toHaveBeenCalledWith(this.template);
    });

    it('should set the template display to none', function () {
      expect(this.template.firstChild.style.display).toBe('none');
    });

    it('should return the templates .firstChild.outerHTML', function () {
      expect(this.renderChildren).toBe(this.template.firstChild.outerHTML);
    });

    describe('if droplab_hidden is false', function () {
      beforeEach(function () {
        this.data = { droplab_hidden: false };
        this.renderChildren = DropDown.prototype.renderChildren.call(this.dropdown, this.data);
      });

      it('should set the template display to block', function () {
        expect(this.template.firstChild.style.display).toBe('block');
      });
    });
  });

  describe('setImagesSrc', function () {
    beforeEach(function () {
      this.dropdown = {};
      this.template = { querySelectorAll: () => {} };

      spyOn(this.template, 'querySelectorAll').and.returnValue([]);

      DropDown.prototype.setImagesSrc.call(this.dropdown, this.template);
    });

    it('should call .querySelectorAll', function () {
      expect(this.template.querySelectorAll).toHaveBeenCalledWith('img[data-src]');
    });
  });

  describe('show', function () {
    beforeEach(function () {
      this.list = { style: {} };
      this.dropdown = { list: this.list, hidden: true };

      DropDown.prototype.show.call(this.dropdown);
    });

    it('it should set .list display to block', function () {
      expect(this.list.style.display).toBe('block');
    });

    it('it should set .hidden to false', function () {
      expect(this.dropdown.hidden).toBe(false);
    });

    describe('if .hidden is false', function () {
      beforeEach(function () {
        this.list = { style: {} };
        this.dropdown = { list: this.list, hidden: false };

        this.show = DropDown.prototype.show.call(this.dropdown);
      });

      it('should return undefined', function () {
        expect(this.show).toEqual(undefined);
      });

      it('should not set .list display to block', function () {
        expect(this.list.style.display).not.toEqual('block');
      });
    });
  });

  describe('hide', function () {
    beforeEach(function () {
      this.list = { style: {} };
      this.dropdown = { list: this.list };

      DropDown.prototype.hide.call(this.dropdown);
    });

    it('it should set .list display to none', function () {
      expect(this.list.style.display).toBe('none');
    });

    it('it should set .hidden to true', function () {
      expect(this.dropdown.hidden).toBe(true);
    });
  });

  describe('toggle', function () {
    beforeEach(function () {
      this.hidden = true
      this.dropdown = { hidden: this.hidden, show: () => {}, hide: () => {} };

      spyOn(this.dropdown, 'show');
      spyOn(this.dropdown, 'hide');

      DropDown.prototype.toggle.call(this.dropdown);
    });

    it('should call .show', function () {
      expect(this.dropdown.show).toHaveBeenCalled();
    });

    describe('if .hidden is false', function () {
      beforeEach(function () {
        this.hidden = false
        this.dropdown = { hidden: this.hidden, show: () => {}, hide: () => {} };

        spyOn(this.dropdown, 'show');
        spyOn(this.dropdown, 'hide');

        DropDown.prototype.toggle.call(this.dropdown);
      });

      it('should call .hide', function () {
        expect(this.dropdown.hide).toHaveBeenCalled();
      });
    });
  });

  describe('destroy', function () {
    beforeEach(function () {
      this.list = { removeEventListener: () => {} };
      this.eventWrapper = { clickEvent: 'clickEvent' };
      this.dropdown = { list: this.list, hide: () => {}, eventWrapper: this.eventWrapper };

      spyOn(this.list, 'removeEventListener');
      spyOn(this.dropdown, 'hide');

      DropDown.prototype.destroy.call(this.dropdown);
    });

    it('it should call .hide', function () {
      expect(this.dropdown.hide).toHaveBeenCalled();
    });

    it('it should call .removeEventListener', function () {
      expect(this.list.removeEventListener).toHaveBeenCalledWith('click', this.eventWrapper.clickEvent);
    });
  });
});
