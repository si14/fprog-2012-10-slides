Общий план
----------

Вступление — кратко об облаках
Старая архитектура, боль
Новая архитектура, счастье
Rainbowdash
Twilightsparkle
Zekora → Derpy (CLJS fail)
Сюрприз
Резюме

Вступление
----------

Что представляет из себя типичное «облако» на текущий момент? Это
набор физических серверов, соединённых в сеть и имеющих общее
хранилище данных. На каждой из нод установлен Xen (система
виртуализации aka гипервизор) и XenAPI (система управления Xen'ом). В
терминологии Xen'а на физической ноде (хосте) существует один Dom0 (от
Domain 0) и некоторое количество DomU (от User Domain). Каждый Domain
это инстанс виртуальной машины; с точки зрения домена, он находится
один на ноде и может исполнять любой код в Ring 0. Единственным
отличием от невиртуализированной среды является набор дополнительных
ассемблерных команд, позволяющих «общаться» с гипервизором из Dom0
(???) командами вроде ??? (создать домен/остановить
домен). Естественно, это крайне неудобно. Более того, Xen не
предоставляет средств общения с внешним миром для виртуальных
машин. Поэтому компанией ??? был написан XenAPI, обеспечивающий
консоль управления гипервизором, пулы (совокупность физических нод с
общим хранилищем) и прозрачную для виртуальной машины миграцию внутри
пула (при этом копируется только состояние оперативной памяти, а не
содержимое жёсткого диска, что можно сделать достаточно быстро —
миграция занимает от 20 секунд до 5 минут (???) в зависимости от
нагрузки на машине).

Безусловно, для предоставления качественного сервиса клиентам голого
XenAPI мало. Необходимы, как минимум:
-учёт используемых ресурсов (биллинг);
-управление машинами из биллинга (отключение за неуплату);
-управление машинами из веб-интерфейса (и, желательно, API);
-управление машинами из административной панели (и максимальные
возможности по скриптованию и автоматизации такого управления);
-детектирование нештатных ситуаций и, по возможности, автоматический
ответ на них (выключение машин в случае недоступности хранилища);
-динамическая балансировка нагрузки между нодами и шедулинг подобного
переноса;
-предоставление интерфейсов к машине, не предусмотренных XenAPI
(веб-консоль, realtime потребление).
Вся эта логика реализуется в рамках проекта облака.

Старая архитектура
------------------

В силу исторических причин и актуальности принципа «сначала заставь
это работать, потом сделай это красивым» старая версия представляет из
себя набор отдельных Python- и Bash- скриптов, общающихся через Mongo
и HTTP-интерфейсы. Так или иначе это работает, но поддержка и
расширение этого зоопарка становится всё сложнее (что такое summationd
и чем он отличается от yawndbtiond-obsolete? (???)), также как и
выкатывание в тестовую среду. Отдельных проблем добавляет Mongo с
отсутствием схемы, т.к. в ней много исторических данных от разных
версий одних и тех же скриптов, и отслеживать вручную изменения схемы
(потому что в любом случае скрипты должны писать и читать в каком-то
формате) становится практически невозможно, что в совокупности с
динамичностью питона приносит абсолютно неожиданные ошибки, которые
крайне сложно увидеть в тестовой среде. Кратко: ничему нельзя
доверять. Это утомляет и приносит много боли.

Новая архитектура
-----------------

В конечном счёте боли стало слишком много и вопрос о реализации более
логичной и стройной системы встал ребром. Так как мы обладаем знанием
о внутреннем устройстве системы с одной стороны и потребностями в её
управлении с другой, было решено начать с построения удобного (для нас
в том числе) API и продолжать наращивать элементы поверх него, обладая
логичной базовой моделью (заменяя XenAPI'шные аббревиатуры вроде
VIF/VBD/VDI/BDSM простыми терминами "Disk", "Network interface" и так
далее). На этот момент в команде был некоторый опыт написания
production-кода на Erlang'е и крайне ограниченный (но позитивный) опыт
с Haskell'ом (буквально отдельные небольшие скрипты). Несмотря на это,
идея описывать достаточно сложную внутреннюю логику работы API на
динамическом языке была отвергнута (в конце концов, Python всё ещё
болел). В то же самое время идея писать вообще всё на Haskell'е
пугала, в результате было рпешено использовать гибридную архитектуру —
сетевая часть на Erlang'е, внутреннняя часть на Haskell'е.
