const ciIconPartialPending = `<use stroke="#E75E40" stroke-width="2" mask="url(#b)" xlink:href="#a"></use>
                              <rect width="1" height="4" x="5" y="5" fill="#E75E40" rx=".3"></rect>
                              <rect width="1" height="4" x="8" y="5" fill="#E75E40" rx=".3"></rect>`;

const ciIconPartialRunning = `<use stroke="#2D9FD8" stroke-width="2" mask="url(#b)" xlink:href="#a"></use>
                                <path fill="#2D9FD8" d="M7,3.00800862 C9.09023405,3.13960661 10.7448145,4.87657932 10.7448145,7 C10.7448145,9.209139 8.95395346,11 6.74481446,11 C5.4560962,11 4.30972054,10.3905589 3.57817301,9.44416214 L7,7 L7,3.00800862 Z"></path>`;

const ciIconPartialFailed = `<use stroke="#D22852" stroke-width="2" mask="url(#b)" xlink:href="#a"></use>
                            <path fill="#D22852" d="M7.5,6.5 L7.5,4.30578971 C7.5,4.12531853 7.36809219,4 7.20537567,4 L6.79462433,4 C6.63904572,4 6.5,4.13690672 6.5,4.30578971 L6.5,6.5 L4.30578971,6.5 C4.12531853,6.5 4,6.63190781 4,6.79462433 L4,7.20537567 C4,7.36095428 4.13690672,7.5 4.30578971,7.5 L6.5,7.5 L6.5,9.69421029 C6.5,9.87468147 6.63190781,10 6.79462433,10 L7.20537567,10 C7.36095428,10 7.5,9.86309328 7.5,9.69421029 L7.5,7.5 L9.69421029,7.5 C9.87468147,7.5 10,7.36809219 10,7.20537567 L10,6.79462433 C10,6.63904572 9.86309328,6.5 9.69421029,6.5 L7.5,6.5 Z" transform="rotate(45 7 7)"></path>`;

const ciIconPartialCanceled = `<use stroke="#5C5C5C" stroke-width="2" mask="url(#b)" xlink:href="#a"></use>
                               <rect width="10" height="1" x="2" y="6.5" fill="#5C5C5C" transform="rotate(45 7 7)" rx=".3"></rect>`;

const ciIconPartialSkipped = ciIconPartialCanceled;

const ciIconPartialSuccessWithWarnings = `<g fill="#FF8A24" transform="translate(6 3)">
                                            <rect width="2" height="5" rx=".5"></rect>
                                            <rect width="2" height="2" y="6" rx=".5"></rect>
                                          </g>
                                          <use stroke="#FF8A24" stroke-width="2" mask="url(#b)" xlink:href="#a"></use>`;

const ciIconPartialSuccess = `<use stroke="#31AF64" stroke-width="2" mask="url(#b)" xlink:href="#a"></use>
                              <g fill="#31AF64" transform="rotate(45 -.13 10.953)">
                                <rect width="1" height="5" x="2" rx=".3"></rect>
                                <rect width="3" height="1" y="4" rx=".3"></rect>
                              </g>`;
