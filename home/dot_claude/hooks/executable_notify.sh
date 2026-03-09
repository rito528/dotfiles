#!/bin/bash
# Windows Toast Notification for Claude Code

powershell.exe -Command "
[Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] | Out-Null;
\$template = [Windows.UI.Notifications.ToastNotificationManager]::GetTemplateContent([Windows.UI.Notifications.ToastTemplateType]::ToastText02);
\$xml = [xml]\$template.GetXml();
\$xml.toast.visual.binding.text[0].AppendChild(\$xml.CreateTextNode('Claude Code')) | Out-Null;
\$xml.toast.visual.binding.text[1].AppendChild(\$xml.CreateTextNode('Claude Codeから通知があります')) | Out-Null;
\$audio = \$xml.CreateElement('audio');
\$audio.SetAttribute('src', 'ms-winsoundevent:Notification.Reminder');
\$audio.SetAttribute('loop', 'false');
\$xml.toast.AppendChild(\$audio) | Out-Null;
\$serialized = New-Object -TypeName Windows.Data.Xml.Dom.XmlDocument;
\$serialized.LoadXml(\$xml.OuterXml);
\$toast = [Windows.UI.Notifications.ToastNotification]::new(\$serialized);
\$notifier = [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier('Claude Code');
\$notifier.Show(\$toast)
"
